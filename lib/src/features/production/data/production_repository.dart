import 'dart:async';
import 'dart:math';

import 'package:gm_fabrica_monitoramento/src/core/exceptions/base_exception.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/daos/production_dao.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/adjustment_reason_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/hit_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/room_raw_data.dart';
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
  DailyProductionAccountingModel _currentAccounting =
      DailyProductionAccountingModel.zero(DateTime.now());
  List<ProductModel> _availableProducts = ProductionDao.defaultProducts;
  RoomRawData? _currentRoom;
  int? _lastHardwareCount;
  int? _lastBootId;
  int _uncountedDiscardOffset = 0;

  // Streams reativos para a UI (latência zero - Hot Path)
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
  final _productsController =
      StreamController<List<ProductModel>>.broadcast();
  final _roomController = StreamController<RoomRawData?>.broadcast();

  // Buffer em segundo plano para persistência no Drift SQLite (Warm Path)
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
  Stream<List<ProductModel>> get availableProductsStream =>
      _productsController.stream;
  Stream<RoomRawData?> get roomStream => _roomController.stream;

  ProductionBatchModel? get currentActiveBatch => _activeBatch;
  DailyProductionAccountingModel get currentDailyAccounting =>
      _currentAccounting;
  List<ProductModel> get currentProducts => _availableProducts;
  RoomRawData? get currentRoom => _currentRoom;

  Future<void> _init() async {
    // 0. Garante que o catálogo de produtos padrão exista no SQLite
    final productsResult = await _dao.ensureDefaultProducts();
    if (productsResult.isOk) {
      _availableProducts = productsResult.valueOrThrow;
      if (!_productsController.isClosed) {
        _productsController.add(_availableProducts);
      }
    }

    // 1. Verifica e encerra qualquer lote deixado aberto em dias anteriores
    await checkAndCloseExpiredBatches();

    // 2. Carrega lote ativo atual (se houver para o dia de hoje)
    final activeResult = await _dao.getActiveBatch();
    if (activeResult.isOk) {
      _activeBatch = activeResult.valueOrThrow;
      if (_activeBatch != null) {
        _lastHardwareCount = _activeBatch!.actualQuantity;
      }
      if (!_activeBatchController.isClosed) {
        _activeBatchController.add(_activeBatch);
      }
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
        if (!_activeBatchController.isClosed) {
          _activeBatchController.add(null);
        }
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
        if (data.room != null) {
          _currentRoom = data.room;
          if (!_roomController.isClosed) {
            _roomController.add(_currentRoom);
          }
        }
        if (_lastBootId != null && data.bootId != _lastBootId) {
          // ESP32 reiniciou! Ajusta o contador base para evitar saltos negativos
          _lastHardwareCount = null;
        }
        _lastBootId = data.bootId;
        _handleHardwarePulse(data.totalCount, isDirectHit: false);
      }
    });
  }

  /// Processa pulso de contagem recebido do hardware com máxima segurança e velocidade (0ms Hot Path)
  void _handleHardwarePulse(int rawHardwareCount, {required bool isDirectHit}) {
    final now = DateTime.now();

    // Verificação contínua de virada de dia ao receber pulso
    if (_activeBatch != null && !_isToday(_activeBatch!.startedAt)) {
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
      if (delta > 0 && !_conveyorWithoutBatchController.isClosed) {
        _conveyorWithoutBatchController.add(true);
      }
      return;
    }

    // Se temos lote ativo, desativa alerta de sem lote
    if (!_conveyorWithoutBatchController.isClosed) {
      _conveyorWithoutBatchController.add(false);
    }

    if (delta > 0) {
      final boxCap = _activeBatch!.product.defaultBoxCapacity > 0
          ? _activeBatch!.product.defaultBoxCapacity
          : 50;

      // 1. Atualização instantânea em memória para latência zero na UI (Hot Path)
      final updatedActual = _activeBatch!.actualQuantity + delta;
      _activeBatch = _activeBatch!.copyWith(actualQuantity: updatedActual);
      if (!_activeBatchController.isClosed) {
        _activeBatchController.add(_activeBatch);
      }

      // Atualização instantânea (0ms) da contabilidade diária em memória
      final newDailyGross = _currentAccounting.grossCount + delta;
      final newDailyNet =
          (newDailyGross +
                  _uncountedDiscardOffset -
                  _currentAccounting.discardsCount)
              .clamp(0, 99999999);
      _currentAccounting = _currentAccounting.copyWith(
        grossCount: newDailyGross,
        netCount: newDailyNet,
        completedBoxes: newDailyNet ~/ boxCap,
      );
      if (!_dailyAccountingController.isClosed) {
        _dailyAccountingController.add(_currentAccounting);
      }

      // Emite evento de hit para animação/som na UI
      if (!_hitEventController.isClosed) {
        _hitEventController.add((
          rawHardwareCount: rawHardwareCount,
          delta: delta,
          isDirectHit: isDirectHit,
        ));
      }

      // 2. Enfileira no buffer para gravação assíncrona no SQLite em segundo plano (Warm Path)
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

    // Reconcilia estatísticas do dia após salvar no banco
    await refreshDailyAccounting();
  }

  /// Inicia um novo lote de produção para um produto.
  /// Regra de negócio: proibido iniciar outro produto sem antes encerrar o lote atual.
  Future<Result<ProductionBatchModel>> startProductionBatch({
    required ProductModel product,
  }) => Result.catchInAsync(
    fn: () async {
      await checkAndCloseExpiredBatches();

      final activeResult = await _dao.getActiveBatch();
      if (_activeBatch != null ||
          (activeResult.isOk && activeResult.valueOrThrow != null)) {
        throw BaseException(
          error: 'Encerre o lote atual antes de iniciar outro produto.',
          stackTrace: StackTrace.current,
          tag: 'ProductionRepository.startProductionBatch',
        );
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
      if (!_activeBatchController.isClosed) {
        _activeBatchController.add(_activeBatch);
      }
      if (!_conveyorWithoutBatchController.isClosed) {
        _conveyorWithoutBatchController.add(false);
      }

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

          await _flushBuffer();

          final result = await _dao.closeBatch(batch: targetBatch);
          if (result.isError) {
            throw result.errorOrThrow;
          }

          if (_activeBatch?.id == targetBatch.id) {
            _activeBatch = null;
            if (!_activeBatchController.isClosed) {
              _activeBatchController.add(null);
            }
          }

          await refreshDailyAccounting();
          return unit;
        },
        tag: 'ProductionRepository.closeActiveBatch',
      );

  /// Registra ajuste (quebra/descarte com deltaQty < 0 ou adição manual com deltaQty > 0)
  /// com atualização imediata em memória (0ms Hot Path).
  Future<Result<Unit>> registerAdjustment({
    required String batchId,
    required int deltaQty,
    required AdjustmentReasonEnum reason,
    String? observation,
  }) async {
    // 1. Despeja qualquer pulso no buffer antes de calcular excesso e gravar ajuste no banco
    await _flushBuffer();

    final boxCap =
        (_activeBatch?.product.defaultBoxCapacity ?? 50) > 0
            ? (_activeBatch?.product.defaultBoxCapacity ?? 50)
            : 50;

    if (deltaQty < 0) {
      final addedDiscards = deltaQty.abs();
      final excessOverNet = max(0, addedDiscards - _currentAccounting.netCount);
      _uncountedDiscardOffset += excessOverNet;

      final updatedDiscards = _currentAccounting.discardsCount + addedDiscards;
      final updatedNet =
          (_currentAccounting.netCount - addedDiscards).clamp(0, 99999999);
      _currentAccounting = _currentAccounting.copyWith(
        discardsCount: updatedDiscards,
        netCount: updatedNet,
        completedBoxes: updatedNet ~/ boxCap,
      );
    } else if (deltaQty > 0) {
      final updatedGross = _currentAccounting.grossCount + deltaQty;
      final updatedNet = (_currentAccounting.netCount + deltaQty).clamp(
        0,
        99999999,
      );
      _currentAccounting = _currentAccounting.copyWith(
        grossCount: updatedGross,
        netCount: updatedNet,
        completedBoxes: updatedNet ~/ boxCap,
      );
    }
    if (!_dailyAccountingController.isClosed) {
      _dailyAccountingController.add(_currentAccounting);
    }

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

  /// Busca e atualiza a contabilidade diária de ovos (considerando hits ainda no buffer em memória)
  Future<Result<DailyProductionAccountingModel>> refreshDailyAccounting({
    DateTime? date,
  }) async {
    final result = await _dao.getDailyAccounting(date: date);
    if (result.isOk) {
      var accounting = result.valueOrThrow;
      final boxCap =
          (_activeBatch?.product.defaultBoxCapacity ?? 50) > 0
              ? (_activeBatch?.product.defaultBoxCapacity ?? 50)
              : 50;

      final resolvedGross = (_hitBuffer.isNotEmpty &&
              _currentAccounting.grossCount > accounting.grossCount)
          ? _currentAccounting.grossCount
          : accounting.grossCount;

      final resolvedNet =
          (resolvedGross + _uncountedDiscardOffset - accounting.discardsCount)
              .clamp(0, 99999999);

      accounting = accounting.copyWith(
        grossCount: resolvedGross,
        netCount: resolvedNet,
        completedBoxes: _activeBatch != null
            ? (resolvedNet ~/ boxCap)
            : accounting.completedBoxes,
      );

      _currentAccounting = accounting;
      if (!_dailyAccountingController.isClosed) {
        _dailyAccountingController.add(_currentAccounting);
      }
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
    _productsController.close();
    _roomController.close();
  }
}
