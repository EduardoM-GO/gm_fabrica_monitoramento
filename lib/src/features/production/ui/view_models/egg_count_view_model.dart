import 'dart:async';

import 'package:gm_fabrica_monitoramento/src/core/exceptions/base_exception.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/adjustment_reason_enum.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/daily_production_accounting_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/product_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/production_batch_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/data/production_repository.dart';
import 'package:gm_fabrica_monitoramento/src/utils/result.dart';
import 'package:signals/signals.dart';

final class EggCountViewModel {
  final ProductionRepository _repository;

  // --- Signals de Estado do Lote Ativo ---
  late final Signal<ProductionBatchModel?> activeBatch;
  late final Computed<bool> hasActiveBatch;
  late final Computed<String> productName;
  late final Signal<int> defaultBoxCapacity;

  // --- Signals de Contagem do Lote & Caixa ---
  late final Computed<int> batchGrossCount;
  late final Computed<int> currentBoxCount;
  late final Computed<double> boxProgress;
  late final Computed<int> batchCompletedBoxes;

  // --- Signals da Contabilidade Diária de Ovos ---
  late final Signal<int> dailyGrossCount;
  late final Signal<int> dailyDiscardsCount;
  late final Computed<int> dailyNetCount;
  late final Signal<int> dailyCompletedBoxes;

  // --- Signals de Telemetria e Alertas em Tempo Real ---
  late final Signal<bool> isConveyorRunningWithoutBatch;
  late final Signal<bool> isHitAnimating;
  late final Signal<double> eggsPerMinute;

  // Inscrições e Timers internos
  StreamSubscription? _activeBatchSub;
  StreamSubscription? _hitEventSub;
  StreamSubscription? _conveyorAlertSub;
  StreamSubscription? _dailyAccountingSub;
  Timer? _hitAnimationTimer;
  Timer? _speedTickerTimer;

  final List<DateTime> _recentHitTimestamps = [];
  bool _isDisposed = false;

  EggCountViewModel(this._repository) {
    _initSignals();
    _bindRepositoryStreams();
    _startSpeedTicker();
  }

  void _initSignals() {
    activeBatch = signal<ProductionBatchModel?>(_repository.currentActiveBatch);
    hasActiveBatch = computed<bool>(() => activeBatch.value != null);
    productName = computed<String>(
      () => activeBatch.value?.product.name ?? 'Sem Lote Aberto',
    );

    defaultBoxCapacity = signal<int>(
      activeBatch.value?.product.defaultBoxCapacity ?? 50,
    );

    // Contagem bruta do lote atual
    batchGrossCount = computed<int>(
      () => activeBatch.value?.producedQuantity ?? 0,
    );

    // Ovos na caixa atual sendo preenchida
    currentBoxCount = computed<int>(() {
      final capacity = defaultBoxCapacity.value;
      if (capacity <= 0) return 0;
      return batchGrossCount.value % capacity;
    });

    // Progresso percentual da caixa (0.0 a 1.0)
    boxProgress = computed<double>(() {
      final capacity = defaultBoxCapacity.value;
      if (capacity <= 0) return 0.0;
      return (currentBoxCount.value / capacity).clamp(0.0, 1.0);
    });

    // Caixas fechadas no lote atual
    batchCompletedBoxes = computed<int>(() {
      final capacity = defaultBoxCapacity.value;
      if (capacity <= 0) return 0;
      return batchGrossCount.value ~/ capacity;
    });

    // Contabilidade do dia consolidada
    dailyGrossCount = signal<int>(0);
    dailyDiscardsCount = signal<int>(0);
    dailyNetCount = computed<int>(
      () => (dailyGrossCount.value - dailyDiscardsCount.value).clamp(
        0,
        99999999,
      ),
    );
    dailyCompletedBoxes = signal<int>(0);

    // Alertas e telemetria
    isConveyorRunningWithoutBatch = signal<bool>(false);
    isHitAnimating = signal<bool>(false);
    eggsPerMinute = signal<double>(0.0);
  }

  void _bindRepositoryStreams() {
    // 1. Acompanhamento reativo do lote ativo
    _activeBatchSub = _repository.activeBatchStream.listen((batch) {
      activeBatch.value = batch;
      if (batch != null) {
        defaultBoxCapacity.value = batch.product.defaultBoxCapacity;
      }
    });

    // 2. Eventos de pulso em tempo real (0ms latência)
    _hitEventSub = _repository.hitEventStream.listen((event) {
      final now = DateTime.now();
      _recentHitTimestamps.add(now);
      _cleanupOldHits(now);
      eggsPerMinute.value = _calculateSpeed(now);

      // Trigger de animação de hit
      isHitAnimating.value = true;
      _hitAnimationTimer?.cancel();
      _hitAnimationTimer = Timer(const Duration(milliseconds: 250), () {
        if (!_isDisposed) {
          isHitAnimating.value = false;
        }
      });
    });

    // 3. Alerta de esteira rodando sem lote aberto
    _conveyorAlertSub = _repository.conveyorWithoutBatchStream.listen((alert) {
      isConveyorRunningWithoutBatch.value = alert;
    });

    // 4. Contabilidade diária consolidada
    _dailyAccountingSub = _repository.dailyAccountingStream.listen(
      _updateDailyAccounting,
    );
  }

  void _updateDailyAccounting(DailyProductionAccountingModel accounting) {
    batch(() {
      dailyGrossCount.value = accounting.grossCount;
      dailyDiscardsCount.value = accounting.discardsCount;
      dailyCompletedBoxes.value = accounting.completedBoxes;
    });
  }

  void _startSpeedTicker() {
    _speedTickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      _cleanupOldHits(now);
      eggsPerMinute.value = _calculateSpeed(now);
    });
  }

  void _cleanupOldHits(DateTime now) {
    _recentHitTimestamps.removeWhere(
      (time) => now.difference(time).inSeconds > 60,
    );
  }

  double _calculateSpeed(DateTime now) {
    if (_recentHitTimestamps.isEmpty) return 0.0;
    return _recentHitTimestamps.length.toDouble();
  }

  // --- Comandos do Operador ---

  /// Inicia um novo lote de produção com o produto selecionado
  Future<Result<ProductionBatchModel>> startBatch(ProductModel product) async {
    final result = await _repository.startProductionBatch(product: product);
    if (result.isOk) {
      defaultBoxCapacity.value = product.defaultBoxCapacity;
    }
    return result;
  }

  /// Finaliza o lote ativo atual
  Future<Result<Unit>> finishActiveBatch() async {
    final current = activeBatch.value;
    if (current == null) return Result.ok(unit);
    return _repository.closeActiveBatch(batch: current);
  }

  /// Registra descarte / quebra no lote ativo
  Future<Result<Unit>> addDiscards({
    required AdjustmentReasonEnum reason,
    required int quantity,
    String? observation,
  }) async {
    final current = activeBatch.value;
    if (current == null) {
      return Result.error(
        BaseException(
          error: 'Nenhum lote ativo para lançar descarte',
          stackTrace: StackTrace.current,
          tag: 'EggCountViewModel.addDiscards',
        ),
      );
    }

    return _repository.registerAdjustment(
      batchId: current.id,
      deltaQty: -quantity.abs(),
      reason: reason,
      observation: observation,
    );
  }

  /// Atualiza os valores da contabilidade diária
  Future<void> refreshDailyStats() async {
    await _repository.refreshDailyAccounting();
  }

  void dispose() {
    _isDisposed = true;
    _activeBatchSub?.cancel();
    _hitEventSub?.cancel();
    _conveyorAlertSub?.cancel();
    _dailyAccountingSub?.cancel();
    _hitAnimationTimer?.cancel();
    _speedTickerTimer?.cancel();
  }
}
