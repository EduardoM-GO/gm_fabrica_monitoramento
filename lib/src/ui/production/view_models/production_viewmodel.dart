import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/model/telemetry_model.dart';
import '../../../../data/services/audio_service.dart';
import '../../../../domain/entities/batch_adjustment_entity.dart';
import '../../../../domain/repositories/i_production_repository.dart';
import '../../../../domain/repositories/websocket_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../settings/view_models/settings_viewmodel.dart';
import 'production_state.dart';

export 'production_state.dart';

/// ViewModel managing egg packaging line and batch tracking.
/// Implements the official Flutter MVVM architecture pattern.
class ProductionViewModel extends ChangeNotifier {
  final IProductionRepository productionRepo;
  final IWebSocketRepository e;
  final AudioService audioService;
  final SettingsViewModel settingsViewModel;

  ProductionState _state;
  ProductionState get state => _state;

  // Commands for UI actions
  late final Command1<void, String> startBatchCommand;
  late final Command0<void> pauseBatchCommand;
  late final Command0<void> resumeBatchCommand;
  late final Command0<void> finishBatchCommand;
  late final Command1<
    void,
    ({AdjustmentReason reason, int quantity, String? note})
  >
  addAdjustmentCommand;
  late final Command0<void> resetCurrentBoxCommand;
  late final Command0<void> resetDailyTotalCommand;

  StreamSubscription? _statusSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _hitSub;
  StreamSubscription? _telemSub;
  StreamSubscription? _batchWatchSub;
  VoidCallback? _settingsListener;
  Timer? _tickerTimer;
  Timer? _hitAnimationTimer;

  int? _lastRawHardwareCount;
  final List<DateTime> _recentHitTimestamps = [];
  bool _isDisposed = false;

  ProductionViewModel({
    required this.productionRepo,
    required this.webSocketRepo,
    required this.audioService,
    required this.settingsViewModel,
  }) : _state = ProductionState.initial(
         defaultBoxCapacity: settingsViewModel.defaultBoxCapacity,
       ) {
    _initCommands();
    _init();
  }

  void _initCommands() {
    startBatchCommand = Command1(_startBatchAction);
    pauseBatchCommand = Command0(_pauseBatchAction);
    resumeBatchCommand = Command0(_resumeBatchAction);
    finishBatchCommand = Command0(_finishBatchAction);
    addAdjustmentCommand = Command1(_addAdjustmentAction);
    resetCurrentBoxCommand = Command0(() async {
      resetCurrentBox();
      return const Result.ok(null);
    });
    resetDailyTotalCommand = Command0(() async {
      resetDailyTotal();
      return const Result.ok(null);
    });
  }

  void _init() {
    _loadInitialData();

    // WebSocket stream subscriptions
    _statusSub = webSocketRepo.connectionStatusStream.listen((status) {
      _state = _state.copyWith(connectionStatus: status);
      notifyListeners();
    });

    _errorSub = webSocketRepo.errorStream.listen((err) {
      _state = _state.copyWith(
        connectionErrorMessage: err,
        clearConnectionError: err == null,
      );
      notifyListeners();
    });

    _hitSub = webSocketRepo.hitStream.listen(_handleHit);
    _telemSub = webSocketRepo.telemetryStream.listen(_handleTelemetry);

    // Watch active batch from Drift SQLite database
    _batchWatchSub = productionRepo.watchActiveBatch().listen((batch) {
      _state = _state.copyWith(
        activeBatch: batch,
        clearActiveBatch: batch == null,
      );
      notifyListeners();
    });

    // Listen to settings changes
    _settingsListener = () {
      audioService.eggSoundEnabled = settingsViewModel.eggSoundEnabled;
      if (settingsViewModel.defaultBoxCapacity != _state.boxCapacity) {
        _state = _state.copyWith(
          boxCapacity: settingsViewModel.defaultBoxCapacity,
        );
        notifyListeners();
      }
    };
    settingsViewModel.addListener(_settingsListener!);

    // 1-second ticker for speed calculation
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  Future<void> _loadInitialData() async {
    try {
      final products = await productionRepo.getActiveProducts();
      final activeBatch = await productionRepo.getActiveBatch();
      _state = _state.copyWith(
        availableProducts: products,
        activeBatch: activeBatch,
        boxCapacity: activeBatch != null && activeBatch.unitWeightGrams >= 500
            ? 40
            : settingsViewModel.defaultBoxCapacity,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar dados iniciais de produção: $e');
    }
  }

  void _handleHit(HitFrame frame) {
    audioService.playEggHit();
    _processCountUpdate(frame.eggCount, isDirectHit: true);
  }

  void _handleTelemetry(TelemetryFrame frame) {
    if (frame.uptimeMs != _state.uptimeMs) {
      _state = _state.copyWith(uptimeMs: frame.uptimeMs);
      notifyListeners();
    }
    _processCountUpdate(frame.eggCount, isDirectHit: false);
  }

  /// ESP32 Reboot Shield & Differential Pulse Calculation
  void _processCountUpdate(int rawHardwareCount, {required bool isDirectHit}) {
    final now = DateTime.now();
    int delta = 0;

    if (_lastRawHardwareCount == null) {
      _lastRawHardwareCount = rawHardwareCount;
      delta = isDirectHit ? 1 : 0;
    } else if (rawHardwareCount >= _lastRawHardwareCount!) {
      delta = rawHardwareCount - _lastRawHardwareCount!;
      if (isDirectHit && delta == 0) {
        delta = 1;
      }
    } else {
      // Power outage / ESP32 reboot detected (rawHardwareCount < _lastRawHardwareCount)
      debugPrint(
        'ESP32 Reboot detectado: anterior=$_lastRawHardwareCount, novo=$rawHardwareCount',
      );
      delta = rawHardwareCount > 0 ? rawHardwareCount : (isDirectHit ? 1 : 0);
    }

    _lastRawHardwareCount = rawHardwareCount;

    if (delta > 0) {
      _applyCountDelta(delta, rawHardwareCount: rawHardwareCount, now: now);
    }
  }

  void _applyCountDelta(
    int delta, {
    required int rawHardwareCount,
    required DateTime now,
  }) {
    _recentHitTimestamps.add(now);
    _cleanupOldHits(now);

    final newDailyTotal = (_state.dailyTotalEggs + delta).clamp(0, 9999999);
    final totalInBox = _state.currentBoxCount + delta;
    int newBoxCount = totalInBox;
    int completedIncrement = 0;
    bool justCompleted = false;

    if (totalInBox >= _state.boxCapacity) {
      completedIncrement = totalInBox ~/ _state.boxCapacity;
      newBoxCount = totalInBox % _state.boxCapacity;
      justCompleted = true;
      audioService.playBoxCompleted();
    }

    _hitAnimationTimer?.cancel();
    _hitAnimationTimer = Timer(const Duration(milliseconds: 300), () {
      if (!_isDisposed) {
        _state = _state.copyWith(
          isHitAnimating: false,
          isBoxJustCompleted: false,
        );
        notifyListeners();
      }
    });

    // If active batch is in progress, update and persist to Drift
    final batch = _state.activeBatch;
    if (batch != null && batch.status.isInProgress) {
      final newGross = batch.grossProducedCount + delta;
      productionRepo.updateBatchProgress(
        batchId: batch.id,
        grossProducedCount: newGross,
      );
    }

    _state = _state.copyWith(
      lastRawHardwareCount: rawHardwareCount,
      dailyTotalEggs: newDailyTotal,
      currentBoxCount: newBoxCount,
      completedBoxesCount: _state.completedBoxesCount + completedIncrement,
      isHitAnimating: true,
      isBoxJustCompleted: justCompleted,
      lastHitTime: now,
      eggsPerMinute: _calculateEggsPerMinute(now),
    );
    notifyListeners();
  }

  /// Manual increment (+1) triggered by packaging operator
  void incrementManual() {
    audioService.playEggHit();
    final now = DateTime.now();
    _recentHitTimestamps.add(now);
    _cleanupOldHits(now);
    final fakeRaw = (_state.lastRawHardwareCount ?? 0) + 1;
    _applyCountDelta(1, rawHardwareCount: fakeRaw, now: now);
  }

  /// Manual decrement (-1) to undo accidental pulse
  void decrementManual() {
    audioService.playEggUndo();
    if (_state.currentBoxCount > 0) {
      _state = _state.copyWith(
        currentBoxCount: _state.currentBoxCount - 1,
        dailyTotalEggs: (_state.dailyTotalEggs > 0)
            ? _state.dailyTotalEggs - 1
            : 0,
      );
      notifyListeners();
    } else if (_state.completedBoxesCount > 0) {
      _state = _state.copyWith(
        completedBoxesCount: _state.completedBoxesCount - 1,
        currentBoxCount: _state.boxCapacity - 1,
        dailyTotalEggs: (_state.dailyTotalEggs > 0)
            ? _state.dailyTotalEggs - 1
            : 0,
      );
      notifyListeners();
    }
  }

  Future<Result<void>> _startBatchAction(String productId) async {
    try {
      final currentHardwareCount = _state.lastRawHardwareCount ?? 0;
      await productionRepo.startBatch(
        productId: productId,
        initialHardwareCount: currentHardwareCount,
      );
      final product = await productionRepo.getProductById(productId);
      if (product != null) {
        _state = _state.copyWith(
          boxCapacity: product.defaultBoxCapacity,
          clearActionError: true,
        );
        notifyListeners();
      }
      return const Result.ok(null);
    } catch (e) {
      _state = _state.copyWith(actionErrorMessage: 'Falha ao iniciar lote: $e');
      notifyListeners();
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void>> _pauseBatchAction() async {
    final batch = _state.activeBatch;
    if (batch == null) return const Result.ok(null);
    try {
      await productionRepo.pauseBatch(batch.id);
      return const Result.ok(null);
    } catch (e) {
      _state = _state.copyWith(actionErrorMessage: 'Falha ao pausar lote: $e');
      notifyListeners();
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void>> _resumeBatchAction() async {
    final batch = _state.activeBatch;
    if (batch == null) return const Result.ok(null);
    try {
      await productionRepo.resumeBatch(batch.id);
      return const Result.ok(null);
    } catch (e) {
      _state = _state.copyWith(actionErrorMessage: 'Falha ao retomar lote: $e');
      notifyListeners();
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void>> _finishBatchAction() async {
    final batch = _state.activeBatch;
    if (batch == null) return const Result.ok(null);
    try {
      await productionRepo.finishBatch(batch.id);
      return const Result.ok(null);
    } catch (e) {
      _state = _state.copyWith(
        actionErrorMessage: 'Falha ao finalizar lote: $e',
      );
      notifyListeners();
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void>> _addAdjustmentAction(
    ({AdjustmentReason reason, int quantity, String? note}) params,
  ) async {
    final batch = _state.activeBatch;
    if (batch == null) {
      _state = _state.copyWith(
        actionErrorMessage: 'Nenhum lote ativo para lançar descarte',
      );
      notifyListeners();
      return Result.error(Exception('Nenhum lote ativo'));
    }

    try {
      await productionRepo.addAdjustment(
        batchId: batch.id,
        reason: params.reason,
        deltaQuantity: -params.quantity.abs(),
        customNote: params.note,
      );
      return const Result.ok(null);
    } catch (e) {
      _state = _state.copyWith(
        actionErrorMessage: 'Falha ao registrar descarte: $e',
      );
      notifyListeners();
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  // Direct helper wrappers for easy View invocation
  Future<void> startBatch(String productId) =>
      startBatchCommand.execute(productId);
  Future<void> pauseBatch() => pauseBatchCommand.execute();
  Future<void> resumeBatch() => resumeBatchCommand.execute();
  Future<void> finishBatch() => finishBatchCommand.execute();
  Future<void> registerAdjustment({
    required AdjustmentReason reason,
    required int quantity,
    String? customNote,
  }) => addAdjustmentCommand.execute((
    reason: reason,
    quantity: quantity,
    note: customNote,
  ));

  void setBoxCapacity(int capacity) {
    if (capacity <= 0 || capacity == _state.boxCapacity) return;
    _state = _state.copyWith(boxCapacity: capacity);
    notifyListeners();
    settingsViewModel.updateDefaultBoxCapacity(capacity);
  }

  void resetCurrentBox() {
    _state = _state.copyWith(currentBoxCount: 0);
    notifyListeners();
  }

  void resetDailyTotal() {
    _state = _state.copyWith(
      dailyTotalEggs: 0,
      completedBoxesCount: 0,
      currentBoxCount: 0,
    );
    notifyListeners();
  }

  void simulateEggHit() {
    webSocketRepo.simulateEggHit();
  }

  void _onTick() {
    final now = DateTime.now();
    _cleanupOldHits(now);
    _state = _state.copyWith(eggsPerMinute: _calculateEggsPerMinute(now));
    notifyListeners();
  }

  void _cleanupOldHits(DateTime now) {
    _recentHitTimestamps.removeWhere(
      (time) => now.difference(time).inSeconds > 60,
    );
  }

  double _calculateEggsPerMinute(DateTime now) {
    if (_recentHitTimestamps.isEmpty) return 0.0;
    return _recentHitTimestamps.length.toDouble();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _statusSub?.cancel();
    _errorSub?.cancel();
    _hitSub?.cancel();
    _telemSub?.cancel();
    _batchWatchSub?.cancel();
    if (_settingsListener != null) {
      settingsViewModel.removeListener(_settingsListener!);
    }
    _tickerTimer?.cancel();
    _hitAnimationTimer?.cancel();
    startBatchCommand.dispose();
    pauseBatchCommand.dispose();
    resumeBatchCommand.dispose();
    finishBatchCommand.dispose();
    addAdjustmentCommand.dispose();
    resetCurrentBoxCommand.dispose();
    resetDailyTotalCommand.dispose();
    super.dispose();
  }
}
