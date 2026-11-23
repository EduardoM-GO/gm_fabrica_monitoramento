import 'dart:async';
import 'dart:math';

import 'package:gm_fabrica_monitoramento/src/core/exceptions/base_exception.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/adjustment_reason_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/services/audio_service.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/room_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/daily_production_accounting_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/product_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/production_batch_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/data/production_repository.dart';
import 'package:gm_fabrica_monitoramento/src/utils/result.dart';
import 'package:signals/signals.dart';

final class EggCountViewModel {
  final ProductionRepository _repository;
  final AudioService? _audioService;

  // --- Signals de Estado do Lote Ativo & Produtos (Supabase -> SQLite) ---
  late final Signal<ProductionBatchModel?> activeBatch;
  late final Signal<List<ProductModel>> availableProducts;
  late final Signal<bool> isSyncingProducts;
  late final Signal<String?> productsSyncError;
  late final Computed<bool> hasActiveBatch;
  late final Computed<String> productName;
  late final Signal<int> defaultBoxCapacity;

  // --- Signals de Contagem do Lote & Caixa ---
  late final Signal<int> batchManualAdditions;
  late final Signal<int> batchNetAdjustment;
  late final Computed<int> batchGrossCount;
  late final Computed<int> batchEffectiveCount;
  late final Computed<int> currentBoxCount;
  late final Computed<double> boxProgress;
  late final Computed<int> batchCompletedBoxes;

  // --- Signals da Contabilidade Diária de Ovos ---
  late final Signal<int> dailyGrossCount;
  late final Signal<int> dailyDiscardsCount;
  late final Signal<int> dailyNetCount;
  late final Signal<int> dailyCompletedBoxes;

  // --- Signals de Telemetria, Sala e Alertas em Tempo Real ---
  late final Signal<bool> isConveyorRunningWithoutBatch;
  late final Signal<bool> isHitAnimating;
  late final Signal<double> eggsPerMinute;
  late final Signal<RoomRawData?> roomTelemetry;

  // Inscrições e Timers internos
  StreamSubscription? _activeBatchSub;
  StreamSubscription? _hitEventSub;
  StreamSubscription? _conveyorAlertSub;
  StreamSubscription? _dailyAccountingSub;
  StreamSubscription? _productsSub;
  StreamSubscription? _productsLoadingSub;
  StreamSubscription? _productsErrorSub;
  StreamSubscription? _roomSub;
  Timer? _hitAnimationTimer;
  Timer? _speedTickerTimer;

  final List<DateTime> _recentHitTimestamps = [];
  int _lastCompletedBoxes = 0;
  bool _isDisposed = false;

  EggCountViewModel(this._repository, {this._audioService}) {
    _initSignals();
    _bindRepositoryStreams();
    _startSpeedTicker();
  }

  void _initSignals() {
    activeBatch = signal<ProductionBatchModel?>(_repository.currentActiveBatch);
    availableProducts = signal<List<ProductModel>>(_repository.currentProducts);
    isSyncingProducts = signal<bool>(_repository.isSyncingProducts);
    productsSyncError = signal<String?>(_repository.lastProductsSyncError);
    hasActiveBatch = computed<bool>(() => activeBatch.value != null);
    productName = computed<String>(
      () => activeBatch.value?.product.name ?? 'Sem Lote Aberto',
    );

    defaultBoxCapacity = signal<int>(
      activeBatch.value?.product.defaultBoxCapacity ?? 50,
    );

    // Contagem do dia consolidada (inicializada com o cache do repositório)
    final initialAccounting = _repository.currentDailyAccounting;
    dailyGrossCount = signal<int>(initialAccounting.grossCount);
    dailyDiscardsCount = signal<int>(initialAccounting.discardsCount);
    dailyNetCount = signal<int>(initialAccounting.netCount);
    dailyCompletedBoxes = signal<int>(initialAccounting.completedBoxes);

    // Contagem bruta e contagem efetiva líquida (baseada no Líquido do Dia dividido pelo lote)
    batchManualAdditions = signal<int>(0);
    batchNetAdjustment = signal<int>(0);
    batchGrossCount = computed<int>(
      () =>
          (activeBatch.value?.producedQuantity ?? 0) +
          batchManualAdditions.value,
    );
    batchEffectiveCount = computed<int>(() => dailyNetCount.value);

    // Ovos na caixa atual = resto da divisão do Líquido do Dia pela capacidade do lote
    currentBoxCount = computed<int>(() {
      final capacity = defaultBoxCapacity.value;
      if (capacity <= 0) return 0;
      return dailyNetCount.value % capacity;
    });

    // Progresso percentual da caixa (0.0 a 1.0)
    boxProgress = computed<double>(() {
      final capacity = defaultBoxCapacity.value;
      if (capacity <= 0) return 0.0;
      return (currentBoxCount.value / capacity).clamp(0.0, 1.0);
    });

    // Caixas fechadas = inteiro da divisão do Líquido do Dia pela capacidade do lote
    batchCompletedBoxes = computed<int>(() {
      final capacity = defaultBoxCapacity.value;
      if (capacity <= 0) return 0;
      return dailyNetCount.value ~/ capacity;
    });
    _lastCompletedBoxes = batchCompletedBoxes.value;

    // Alertas e telemetria
    isConveyorRunningWithoutBatch = signal<bool>(false);
    isHitAnimating = signal<bool>(false);
    eggsPerMinute = signal<double>(0.0);
    roomTelemetry = signal<RoomRawData?>(_repository.currentRoom);
  }

  void _bindRepositoryStreams() {
    // 1. Acompanhamento reativo do lote ativo
    _activeBatchSub = _repository.activeBatchStream.listen((batch) {
      activeBatch.value = batch;
      if (batch != null) {
        defaultBoxCapacity.value = batch.product.defaultBoxCapacity;
        final currentBoxes = batchCompletedBoxes.value;
        if (currentBoxes > _lastCompletedBoxes) {
          _audioService?.playBoxCompleted();
        }
        _lastCompletedBoxes = currentBoxes;
      } else {
        _lastCompletedBoxes = 0;
      }
    });

    // 2. Eventos de pulso em tempo real (0ms latência)
    _hitEventSub = _repository.hitEventStream.listen((event) {
      final now = DateTime.now();
      _recentHitTimestamps.add(now);
      _cleanupOldHits(now);
      eggsPerMinute.value = _calculateSpeed(now);

      _audioService?.playEggHit();

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
      if (alert) {
        _audioService?.playConveyorAlert();
      }
    });

    // 4. Contabilidade diária consolidada (0ms Hot Path + Warm Reconcile)
    _dailyAccountingSub = _repository.dailyAccountingStream.listen(
      _updateDailyAccounting,
    );

    // 5. Catálogo de produtos do Supabase e telemetria da sala
    _productsSub = _repository.availableProductsStream.listen((products) {
      availableProducts.value = products;
    });
    _productsLoadingSub = _repository.isSyncingProductsStream.listen((loading) {
      isSyncingProducts.value = loading;
    });
    _productsErrorSub = _repository.productsSyncErrorStream.listen((err) {
      productsSyncError.value = err;
    });

    _roomSub = _repository.roomStream.listen((room) {
      roomTelemetry.value = room;
    });
  }

  void _updateDailyAccounting(DailyProductionAccountingModel accounting) {
    batch(() {
      dailyGrossCount.value = accounting.grossCount;
      dailyDiscardsCount.value = accounting.discardsCount;
      dailyNetCount.value = accounting.netCount;
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

  /// Sincroniza sob demanda a lista de produtos ativos do Supabase
  Future<Result<List<ProductModel>>> refreshProducts() {
    return _repository.refreshProductsFromSupabase();
  }

  /// Inicia um novo lote de produção com o produto selecionado
  Future<Result<ProductionBatchModel>> startBatch(ProductModel product) async {
    final result = await _repository.startProductionBatch(product: product);
    if (result.isOk) {
      batchManualAdditions.value = 0;
      batchNetAdjustment.value = 0;
      defaultBoxCapacity.value = product.defaultBoxCapacity;
      _lastCompletedBoxes = 0;
    }
    return result;
  }

  /// Finaliza o lote ativo atual
  Future<Result<Unit>> finishActiveBatch() async {
    final current = activeBatch.value;
    if (current == null) return const Result.ok(unit);
    final res = await _repository.closeActiveBatch(batch: current);
    if (res.isOk) {
      batchManualAdditions.value = 0;
      batchNetAdjustment.value = 0;
    }
    return res;
  }

  /// Registra ajuste (quebra/descarte negativo ou correção manual positiva) no lote ativo
  Future<Result<Unit>> addDiscards({
    required AdjustmentReasonEnum reason,
    required int quantity,
    String? observation,
  }) async {
    final current = activeBatch.value;
    if (current == null) {
      return Result.error(
        BaseException(
          error: 'Nenhum lote ativo para lançar ajuste',
          stackTrace: StackTrace.current,
          tag: 'EggCountViewModel.addDiscards',
        ),
      );
    }

    final absQty = quantity.abs();
    final signedDelta = reason.isAddition ? absQty : -absQty;
    final rawProduced = current.producedQuantity;
    final boxCap = defaultBoxCapacity.value > 0 ? defaultBoxCapacity.value : 50;

    if (reason.isAddition) {
      batchManualAdditions.value += absQty;
      batchNetAdjustment.value += absQty;
      final newNet = (dailyNetCount.value + absQty).clamp(0, 99999999);
      batch(() {
        dailyGrossCount.value += absQty;
        dailyNetCount.value = newNet;
        dailyCompletedBoxes.value = newNet ~/ boxCap;
      });
      _audioService?.playEggHit();
    } else {
      batchNetAdjustment.value = max(
        -rawProduced,
        batchNetAdjustment.value - absQty,
      );
      final newNet = (dailyNetCount.value - absQty).clamp(0, 99999999);
      batch(() {
        dailyDiscardsCount.value += absQty;
        dailyNetCount.value = newNet;
        dailyCompletedBoxes.value = newNet ~/ boxCap;
      });
      _audioService?.playEggUndo();
    }
    _lastCompletedBoxes = batchCompletedBoxes.value;

    final res = await _repository.registerAdjustment(
      batchId: current.id,
      deltaQty: signedDelta,
      reason: reason,
      observation: observation,
    );
    _updateDailyAccounting(_repository.currentDailyAccounting);
    return res;
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
    _productsSub?.cancel();
    _productsLoadingSub?.cancel();
    _productsErrorSub?.cancel();
    _roomSub?.cancel();
    _hitAnimationTimer?.cancel();
    _speedTickerTimer?.cancel();
  }
}
