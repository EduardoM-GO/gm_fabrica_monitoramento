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
  late final Signal<int> carryOverUnits;
  late final Computed<int> batchGrossCount;
  late final Computed<int> batchEffectiveCount;
  late final Computed<bool> isCompletingCarryOverBox;
  late final Computed<int> currentBoxTargetCapacity;
  late final Computed<int> currentBoxCount;
  late final Computed<double> boxProgress;
  late final Computed<int> batchCompletedBoxes;

  // --- Signals da Contabilidade Diária de Ovos ---
  late final Signal<int> dailyGrossCount;
  late final Signal<int> dailyDiscardsCount;
  late final Signal<int> dailyNetCount;
  late final Signal<int> dailyCompletedBoxes;

  // --- Signals de Telemetria, Sala e Alertas em Tempo Real (Micro-States) ---
  late final Signal<bool> isConveyorRunningWithoutBatch;
  late final Signal<bool> isHitAnimating;
  late final Signal<DateTime?> lastHitAt;
  late final Signal<int> lastHitSecondsAgo;
  late final Signal<int> lastHitDelta;
  late final Signal<String?> lastHitTransitionLabel;
  late final Signal<bool> isRapidPulseWarning;
  late final Signal<String?> rapidPulseWarningText;
  late final Computed<bool> isRecentHitHighlight;
  late final Computed<String?> lastHitConfirmationText;
  late final Signal<double> eggsPerMinute;
  late final Signal<RoomRawData?> roomTelemetry;
  late final Signal<String> roomSummaryText;
  late final Signal<bool> isRoomClimateAlert;

  // Inscrições e Timers internos
  StreamSubscription? _activeBatchSub;
  StreamSubscription? _hitEventSub;
  StreamSubscription? _conveyorAlertSub;
  StreamSubscription? _dailyAccountingSub;
  StreamSubscription? _productsSub;
  StreamSubscription? _productsLoadingSub;
  StreamSubscription? _productsErrorSub;
  StreamSubscription? _roomSub;
  StreamSubscription? _carryOverSub;
  Timer? _hitAnimationTimer;
  Timer? _rapidPulseClearTimer;
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
    carryOverUnits = signal<int>(_repository.currentActiveCarryOverUnits);
    batchGrossCount = computed<int>(
      () =>
          (activeBatch.value?.producedQuantity ?? 0) +
          batchManualAdditions.value,
    );
    batchEffectiveCount = computed<int>(() => dailyNetCount.value);

    // Indica se ainda estamos completando a 1ª caixa que veio aberta do lote anterior
    // (ex: tinha 23 na caixa anterior -> faltam 27 -> enquanto dailyNetCount < 27, mostra 0 / 27 .. 26 / 27)
    isCompletingCarryOverBox = computed<bool>(() {
      final capacity = defaultBoxCapacity.value;
      final carry = carryOverUnits.value;
      if (capacity <= 0 || carry <= 0 || carry >= capacity) return false;
      final remainingForFirstBox = capacity - carry;
      return dailyNetCount.value < remainingForFirstBox;
    });

    // Capacidade alvo exibida na caixa atual:
    // - Na 1ª caixa continuada: (capacidade - carryOver), ex: 50 - 23 = 27 (exibe "0 / 27")
    // - Nas demais caixas (ou sem sobra): capacidade normal (exibe "0 / 50")
    currentBoxTargetCapacity = computed<int>(() {
      final capacity = defaultBoxCapacity.value;
      if (capacity <= 0) return 50;
      if (isCompletingCarryOverBox.value) {
        return capacity - carryOverUnits.value;
      }
      return capacity;
    });

    // Ovos colocados hoje na caixa atual:
    // - Enquanto completa a 1ª caixa continuada (dailyNet < 27): mostra de 0 até 26 (sobre "/ 27")
    // - Após fechar a 1ª caixa (dailyNet >= 27): mostra (dailyNet + 23) % 50 (0 até 49 sobre "/ 50")
    currentBoxCount = computed<int>(() {
      final capacity = defaultBoxCapacity.value;
      if (capacity <= 0) return 0;
      final net = dailyNetCount.value;
      if (isCompletingCarryOverBox.value) {
        return net;
      }
      final carry = carryOverUnits.value.clamp(0, capacity - 1);
      return (net + carry) % capacity;
    });

    // Progresso percentual da caixa atual (0.0 a 1.0)
    boxProgress = computed<double>(() {
      final targetCap = currentBoxTargetCapacity.value;
      if (targetCap <= 0) return 0.0;
      return (currentBoxCount.value / targetCap).clamp(0.0, 1.0);
    });

    // Caixas fechadas = inteiro da divisão de (Líquido do Dia + Sobra da Caixa Anterior) pela capacidade
    batchCompletedBoxes = computed<int>(() {
      final capacity = defaultBoxCapacity.value;
      if (capacity <= 0) return 0;
      final carry = carryOverUnits.value.clamp(0, capacity - 1);
      return (dailyNetCount.value + carry) ~/ capacity;
    });
    _lastCompletedBoxes = batchCompletedBoxes.value;

    // Alertas e telemetria
    isConveyorRunningWithoutBatch = signal<bool>(false);
    isHitAnimating = signal<bool>(false);
    lastHitAt = signal<DateTime?>(null);
    lastHitSecondsAgo = signal<int>(0);
    lastHitDelta = signal<int>(1);
    lastHitTransitionLabel = signal<String?>(null);
    isRapidPulseWarning = signal<bool>(false);
    rapidPulseWarningText = signal<String?>(null);
    isRecentHitHighlight = computed<bool>(
      () => lastHitAt.value != null && lastHitSecondsAgo.value <= 5,
    );
    lastHitConfirmationText = computed<String?>(() {
      final hitAt = lastHitAt.value;
      final transition = lastHitTransitionLabel.value;
      if (hitAt == null || transition == null || !hasActiveBatch.value) {
        return null;
      }
      final rapidWarn = rapidPulseWarningText.value;
      if (isRapidPulseWarning.value && rapidWarn != null) {
        return rapidWarn;
      }
      final secs = lastHitSecondsAgo.value;
      final delta = lastHitDelta.value;
      if (secs <= 1) {
        return '✓ +$delta CONTADO • AGORA ($transition)';
      }
      if (secs <= 5) {
        return '✓ +$delta CONTADO • há ${secs}s ($transition)';
      }
      if (secs < 60) {
        return 'Último: há ${secs}s ($transition)';
      }
      final mins = secs ~/ 60;
      return 'Último: há ${mins}m ($transition)';
    });
    eggsPerMinute = signal<double>(0.0);
    roomTelemetry = signal<RoomRawData?>(_repository.currentRoom);
    roomSummaryText = signal<String>(_formatRoom(_repository.currentRoom));
    isRoomClimateAlert = signal<bool>(
      _isRoomOutOfRange(_repository.currentRoom),
    );
  }

  static bool _isRoomOutOfRange(RoomRawData? room) =>
      room != null && (room.temp >= 25.0 || room.humidity >= 68.0);

  static String _formatRoom(RoomRawData? room) => room != null
      ? 'Sala: ${room.temp.toStringAsFixed(1)} °C • ${room.humidity.toStringAsFixed(0)}% UR'
      : 'Sala: --.- °C • --% UR';

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

      _recordVisualHitConfirmation(delta: event.delta, now: now);
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
      final formatted = _formatRoom(room);
      if (roomSummaryText.value != formatted) {
        roomSummaryText.value = formatted;
      }
      final alert = _isRoomOutOfRange(room);
      if (isRoomClimateAlert.value != alert) {
        isRoomClimateAlert.value = alert;
      }
    });

    _carryOverSub = _repository.activeCarryOverUnitsStream.listen((carry) {
      carryOverUnits.value = carry;
    });
  }

  void _updateDailyAccounting(DailyProductionAccountingModel accounting) {
    batch(() {
      if (dailyGrossCount.value != accounting.grossCount) {
        dailyGrossCount.value = accounting.grossCount;
      }
      if (dailyDiscardsCount.value != accounting.discardsCount) {
        dailyDiscardsCount.value = accounting.discardsCount;
      }
      if (dailyNetCount.value != accounting.netCount) {
        dailyNetCount.value = accounting.netCount;
      }
      if (dailyCompletedBoxes.value != accounting.completedBoxes) {
        dailyCompletedBoxes.value = accounting.completedBoxes;
      }
    });
  }

  int _boxDisplayCountForNet(int netValue, int cap, int carry) {
    final safeCarry = carry.clamp(0, cap - 1);
    if (safeCarry > 0) {
      final remFirst = cap - safeCarry;
      if (netValue < remFirst) {
        return netValue;
      }
      if (netValue == remFirst) {
        return remFirst;
      }
    }
    final mod = (netValue + safeCarry) % cap;
    return (netValue > 0 && mod == 0) ? cap : mod;
  }

  void _recordVisualHitConfirmation({
    required int delta,
    required DateTime now,
    bool isManualAdjustment = false,
  }) {
    final safeDelta = max(1, delta);
    final cap = defaultBoxCapacity.value > 0 ? defaultBoxCapacity.value : 50;
    final carry = carryOverUnits.value.clamp(0, cap - 1);
    final afterNet = dailyNetCount.value;
    final beforeNet = max(0, afterNet - safeDelta);
    final beforeBox = (carry > 0 && beforeNet < (cap - carry))
        ? beforeNet
        : ((beforeNet + carry) % cap);
    final afterBox = _boxDisplayCountForNet(afterNet, cap, carry);
    final transition = '$beforeBox → $afterBox';

    final prevHitAt = lastHitAt.value;
    final intervalMs = prevHitAt != null
        ? now.difference(prevHitAt).inMilliseconds
        : 999999;

    // Detecta pulso rápido (< 2.2s entre dois ovos na esteira ou salto > 1 de hardware):
    // avisa visualmente o operador para conferir se foram 2 operadores ou repique do sensor.
    final isRapid =
        !isManualAdjustment && (intervalMs <= 2200 || safeDelta > 1);

    batch(() {
      lastHitDelta.value = safeDelta;
      lastHitTransitionLabel.value = transition;
      lastHitSecondsAgo.value = 0;
      lastHitAt.value = now;
      isHitAnimating.value = true;

      if (isRapid) {
        final secsSpan = max(0, (intervalMs / 1000).round());
        final qtyInBurst = safeDelta > 1 ? safeDelta : 2;
        isRapidPulseWarning.value = true;
        rapidPulseWarningText.value =
            '⚡ PULSO RÁPIDO (+$qtyInBurst em ${secsSpan}s • $transition) • Confira';
      }
    });

    if (isRapid) {
      _rapidPulseClearTimer?.cancel();
      _rapidPulseClearTimer = Timer(const Duration(seconds: 8), () {
        if (!_isDisposed) {
          isRapidPulseWarning.value = false;
          rapidPulseWarningText.value = null;
        }
      });
    }

    _hitAnimationTimer?.cancel();
    _hitAnimationTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!_isDisposed) {
        isHitAnimating.value = false;
      }
    });
  }

  void _clearVisualHitConfirmation() {
    _hitAnimationTimer?.cancel();
    _rapidPulseClearTimer?.cancel();
    batch(() {
      isHitAnimating.value = false;
      isRapidPulseWarning.value = false;
      rapidPulseWarningText.value = null;
      lastHitAt.value = null;
      lastHitSecondsAgo.value = 0;
      lastHitTransitionLabel.value = null;
    });
  }

  void _startSpeedTicker() {
    _speedTickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final hitAt = lastHitAt.value;
      if (hitAt != null) {
        final elapsedSec = max(0, now.difference(hitAt).inSeconds);
        if (lastHitSecondsAgo.value != elapsedSec) {
          lastHitSecondsAgo.value = elapsedSec;
        }
      }

      if (_recentHitTimestamps.isEmpty) {
        if (eggsPerMinute.value != 0.0) {
          eggsPerMinute.value = 0.0;
        }
        return;
      }
      _cleanupOldHits(now);
      final newSpeed = _calculateSpeed(now);
      if (eggsPerMinute.value != newSpeed) {
        eggsPerMinute.value = newSpeed;
      }
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

  /// Consulta quantos ovos sobraram na última caixa aberta do lote anterior
  Future<Result<({int carryOverUnits, String? sourceProductName})>>
  getLastOpenBoxRemainder({
    String? productId,
    int? targetBoxCapacity,
  }) {
    return _repository.getLastOpenBoxRemainder(
      productId: productId,
      targetBoxCapacity: targetBoxCapacity,
    );
  }

  /// Inicia um novo lote de produção com o produto selecionado
  /// [carryOverUnits]: ovos que já estavam na última caixa aberta da produção anterior (ex: 23)
  Future<Result<ProductionBatchModel>> startBatch(
    ProductModel product, {
    int carryOverUnits = 0,
  }) async {
    final result = await _repository.startProductionBatch(
      product: product,
      carryOverUnits: carryOverUnits,
    );
    if (result.isOk) {
      final cap = product.defaultBoxCapacity > 0
          ? product.defaultBoxCapacity
          : 50;
      batchManualAdditions.value = 0;
      batchNetAdjustment.value = 0;
      this.carryOverUnits.value = carryOverUnits.clamp(0, cap - 1);
      defaultBoxCapacity.value = product.defaultBoxCapacity;
      _lastCompletedBoxes = batchCompletedBoxes.value;
      _clearVisualHitConfirmation();
    }
    return result;
  }

  /// Troca o produto ativo do dia (fecha o lote anterior com a contagem atual e abre
  /// o novo produto imediatamente, mantendo a produção aberta até o final do dia)
  Future<Result<ProductionBatchModel>> switchProduct(
    ProductModel newProduct, {
    int carryOverUnits = 0,
  }) async {
    final result = await _repository.switchActiveBatchProduct(
      newProduct: newProduct,
      carryOverUnits: carryOverUnits,
    );
    if (result.isOk) {
      final cap = newProduct.defaultBoxCapacity > 0
          ? newProduct.defaultBoxCapacity
          : 50;
      batchManualAdditions.value = 0;
      batchNetAdjustment.value = 0;
      this.carryOverUnits.value = carryOverUnits.clamp(0, cap - 1);
      defaultBoxCapacity.value = newProduct.defaultBoxCapacity;
      _lastCompletedBoxes = batchCompletedBoxes.value;
      _clearVisualHitConfirmation();
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
      carryOverUnits.value = 0;
      _clearVisualHitConfirmation();
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
    final carry = carryOverUnits.value.clamp(0, boxCap - 1);

    if (reason.isAddition) {
      batchManualAdditions.value += absQty;
      batchNetAdjustment.value += absQty;
      final newNet = (dailyNetCount.value + absQty).clamp(0, 99999999);
      batch(() {
        dailyGrossCount.value += absQty;
        dailyNetCount.value = newNet;
        dailyCompletedBoxes.value = (newNet + carry) ~/ boxCap;
      });
      _audioService?.playEggHit();
      _recordVisualHitConfirmation(
        delta: absQty,
        now: DateTime.now(),
        isManualAdjustment: true,
      );
    } else {
      batchNetAdjustment.value = max(
        -rawProduced,
        batchNetAdjustment.value - absQty,
      );
      final newNet = (dailyNetCount.value - absQty).clamp(0, 99999999);
      batch(() {
        dailyDiscardsCount.value += absQty;
        dailyNetCount.value = newNet;
        dailyCompletedBoxes.value = (newNet + carry) ~/ boxCap;
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
    _carryOverSub?.cancel();
    _hitAnimationTimer?.cancel();
    _rapidPulseClearTimer?.cancel();
    _speedTickerTimer?.cancel();
  }
}
