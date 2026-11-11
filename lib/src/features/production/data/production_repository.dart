import 'dart:async';

import 'package:gm_fabrica_monitoramento/src/data/local/daos/production_dao.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/adjustment_reason_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/hit_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/telemetry_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/daily_production_accounting_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/product_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/production_batch_model.dart';
import 'package:gm_fabrica_monitoramento/src/utils/result.dart';

final class ProductionRepository {
  final ProductionDao _dao;
  final WebsocketService _wsService;

  StreamSubscription? _wsSubscription;
  Timer? _midnightTimer;
  Timer? _bufferFlushTimer;

  ProductionBatchModel? _activeBatch;
  int? _lastHardwareCount;
  int? _lastBootId;

  // Streams reativos para a UI (latência zero)
  final _activeBatchController =
      StreamController<ProductionBatchModel?>.broadcast();
  final _hitEventController =
      StreamController<
        ({int rawHardwareCount, int delta, bool isDirectHit})
      >.broadcast();
  final _conveyorWithoutBatchController =
      StreamController<bool>.broadcast();
  final _dailyAccountingController =
      StreamController<DailyProductionAccountingModel>.broadcast();

  // Buffer em segundo plano para persistência no Drift SQLite
  final List<({String batchId, int hardwareCount, DateTime timestamp})>
  _hitBuffer = [];

  ProductionRepository(this._dao, this._wsService) {
    _startHardwareListener();
    _init();
  }

  Stream<ProductionBatchModel?> get activeBatchStream =>
      _activeBatchController.stream;
  Stream<({int rawHardwareCount, int delta, bool isDirectHit})>
  get hitEventStream => _hitEventController.stream;
  Stream<bool> get conveyorWithoutBatchStream =>
      _conveyorWithoutBatchController.stream;
  Stream<DailyProductionAccountingModel> get dailyAccountingStream =>
      _dailyAccountingController.stream;

  ProductionBatchModel? get currentActiveBatch => _activeBatch;

  Future<void> _init() async {
    // 1. Verifica e encerra qualquer lote deixado aberto em dias anteriores
    await checkAndCloseExpiredBatches();

    // 2. Carrega lote ativo atual (se houver para o dia de hoje)
    final activeResult = await _dao.getActiveBatch();
    if (activeResult.isOk) {
      _activeBatch = activeResult.valueOrThrow;
      if (_activeBatch != null) {
        _lastHardwareCount = _activeBatch!.actualQuantity;
      }
      _activeBatchController.add(_activeBatch);
    }

    // 3. Emite a contabilidade inicial do dia
    await refreshDailyAccounting();

    // 4. Agenda timer para a virada da meia-noite (00:00:00)
    _scheduleMidnightTimer();
  }

  void _scheduleMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final duration = tomorrow.difference(now) + const Duration(seconds: 1);

    _midnightTimer = Timer(duration, () async {
      await checkAndCloseExpiredBatches();
      await refreshDailyAccounting();
      _scheduleMidnightTimer();
    });
  }

  /// Verifica se virou o dia e finaliza automaticamente lotes pendentes
  Future<Result<int>> checkAndCloseExpiredBatches() async {
    // Despeja buffer pendente antes de fechar lotes expirados
    await _flushBuffer();

    final result = await _dao.autoCloseExpiredBatches();
    if (result.isOk && result.valueOrThrow > 0) {
      // Se o lote ativo que tínhamos em memória pertencia ao dia anterior, desativa-o
      if (_activeBatch != null && !_isToday(_activeBatch!.startedAt)) {
        _activeBatch = null;
        _activeBatchController.add(null);
      }
    }
    return result;
  }

  void _startHardwareListener() {
    _wsSubscription?.cancel();
    _wsSubscription = _wsService.rawDataStream.listen((data) {
      if (data is HitRawData) {
        _handleHardwarePulse(data.totalCount, isDirectHit: true);
      } else if (data is TelemetryRawData) {
        if (_lastBootId != null && data.bootId != _lastBootId) {
          // ESP32 reiniciou! Ajusta o contador base para evitar saltos negativos
          _lastHardwareCount = null;
        }
        _lastBootId = data.bootId;
        _handleHardwarePulse(data.totalCount, isDirectHit: false);
      }
    });
  }

  /// Processa pulso de contagem recebido do hardware com máxima segurança e velocidade
  void _handleHardwarePulse(int rawHardwareCount, {required bool isDirectHit}) {
    final now = DateTime.now();

    // Verificação contínua de virada de dia ao receber pulso
    if (_activeBatch != null && !_isToday(_activeBatch!.startedAt)) {
      // Virou o dia! Encerra o lote anterior imediatamente e aguarda operador
      checkAndCloseExpiredBatches();
      refreshDailyAccounting();
      return;
    }

    // Cálculo do pulso diferencial (escudo contra reboot e reconexões)
    int delta = 0;
    if (_lastHardwareCount == null) {
      _lastHardwareCount = rawHardwareCount;
      delta = isDirectHit ? 1 : 0;
    } else if (rawHardwareCount >= _lastHardwareCount!) {
      delta = rawHardwareCount - _lastHardwareCount!;
      if (isDirectHit && delta == 0) {
        delta = 1;
      }
    } else {
      // Reboot detectado (contador reiniciou em 0)
      delta = rawHardwareCount > 0 ? rawHardwareCount : (isDirectHit ? 1 : 0);
    }

    _lastHardwareCount = rawHardwareCount;

    // Se a esteira rodou (houve pulso), mas NÃO existe lote ativo:
    if (_activeBatch == null) {
      if (delta > 0) {
        // Dispara alerta imediato para a UI: esteira rodando sem lote aberto!
        _conveyorWithoutBatchController.add(true);
      }
      return;
    }

    // Se temos lote ativo, desativa alerta de sem lote
    _conveyorWithoutBatchController.add(false);

    if (delta > 0) {
      // 1. Atualização instantânea em memória para latência zero na UI
      final updatedActual = _activeBatch!.actualQuantity + delta;
      _activeBatch = _activeBatch!.copyWith(actualQuantity: updatedActual);
      _activeBatchController.add(_activeBatch);

      // Emite evento de hit para animação/som na UI
      _hitEventController.add((
        rawHardwareCount: rawHardwareCount,
        delta: delta,
        isDirectHit: isDirectHit,
      ));

      // 2. Enfileira no buffer para gravação assíncrona no SQLite em segundo plano
      _queueHitForPersistence(_activeBatch!.id, updatedActual, now);
    }
  }

  void _queueHitForPersistence(
    String batchId,
    int hardwareCount,
    DateTime timestamp,
  ) {
    _hitBuffer.add((
      batchId: batchId,
      hardwareCount: hardwareCount,
      timestamp: timestamp,
    ));

    if (_hitBuffer.length >= 10) {
      _flushBuffer();
    } else {
      _bufferFlushTimer ??= Timer(
        const Duration(milliseconds: 1500),
        _flushBuffer,
      );
    }
  }

  Future<void> _flushBuffer() async {
    _bufferFlushTimer?.cancel();
    _bufferFlushTimer = null;

    if (_hitBuffer.isEmpty) return;

    final hitsToWrite =
        List<({String batchId, int hardwareCount, DateTime timestamp})>.from(
          _hitBuffer,
        );
    _hitBuffer.clear();

    final lastHit = hitsToWrite.last;
    await _dao.batchLogTimelineHits(hitsToWrite);
    await _dao.updateBatchProgress(
      batchId: lastHit.batchId,
      actualHardwareCount: lastHit.hardwareCount,
    );

    // Atualiza estatísticas do dia após salvar no banco
    await refreshDailyAccounting();
  }

  /// Inicia um novo lote de produção para um produto
  Future<Result<ProductionBatchModel>> startProductionBatch({
    required ProductModel product,
  }) => Result.catchInAsync(
    fn: () async {
      await checkAndCloseExpiredBatches();

      final activeResult = await _dao.getActiveBatch();
      if (activeResult.isOk && activeResult.valueOrThrow != null) {
        // Já existe um lote aberto para hoje, encerra-o primeiro antes de iniciar outro produto
        await closeActiveBatch(batch: activeResult.valueOrThrow!);
      }

      final result = await _dao.startBatch(
        product: product,
        currentHardwareCount: _lastHardwareCount,
      );

      if (result.isError) {
        throw result.errorOrThrow;
      }

      _activeBatch = result.valueOrThrow;
      _lastHardwareCount = _activeBatch!.actualQuantity;
      _activeBatchController.add(_activeBatch);
      _conveyorWithoutBatchController.add(false);

      await refreshDailyAccounting();
      return _activeBatch!;
    },
    tag: 'ProductionRepository.startProductionBatch',
  );

  /// Fecha manualmente o lote ativo
  Future<Result<Unit>> closeActiveBatch({ProductionBatchModel? batch}) =>
      Result.catchInAsync(
        fn: () async {
          final targetBatch = batch ?? _activeBatch;
          if (targetBatch == null) return unit;

          // Despeja qualquer contagem pendente no buffer
          await _flushBuffer();

          final result = await _dao.closeBatch(batch: targetBatch);
          if (result.isError) {
            throw result.errorOrThrow;
          }

          if (_activeBatch?.id == targetBatch.id) {
            _activeBatch = null;
            _activeBatchController.add(null);
          }

          await refreshDailyAccounting();
          return unit;
        },
        tag: 'ProductionRepository.closeActiveBatch',
      );

  /// Registra descarte / quebra
  Future<Result<Unit>> registerAdjustment({
    required String batchId,
    required int deltaQty,
    required AdjustmentReasonEnum reason,
    String? observation,
  }) async {
    final result = await _dao.addAdjustment(
      batchId: batchId,
      deltaQty: deltaQty,
      reason: reason,
      observation: observation,
    );

    if (result.isOk) {
      await refreshDailyAccounting();
    }
    return result;
  }

  /// Busca e atualiza a contabilidade diária de ovos
  Future<Result<DailyProductionAccountingModel>> refreshDailyAccounting({
    DateTime? date,
  }) async {
    final result = await _dao.getDailyAccounting(date: date);
    if (result.isOk) {
      _dailyAccountingController.add(result.valueOrThrow);
    }
    return result;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void dispose() {
    _wsSubscription?.cancel();
    _midnightTimer?.cancel();
    _bufferFlushTimer?.cancel();
    _flushBuffer();
    _activeBatchController.close();
    _hitEventController.close();
    _conveyorWithoutBatchController.close();
    _dailyAccountingController.close();
  }
}
