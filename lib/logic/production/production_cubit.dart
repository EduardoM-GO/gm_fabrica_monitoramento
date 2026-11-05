import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/telemetry_model.dart';
import '../../data/repositories/websocket_repository_impl.dart';
import '../../data/services/audio_service.dart';
import '../../domain/entities/batch_adjustment_entity.dart';
import '../../domain/repositories/i_production_repository.dart';
import '../settings/settings_cubit.dart';
import 'production_state.dart';

class ProductionCubit extends Cubit<ProductionState> {
  final IProductionRepository productionRepo;
  final IWebSocketRepository webSocketRepo;
  final AudioService audioService;
  final SettingsCubit settingsCubit;

  StreamSubscription? _statusSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _hitSub;
  StreamSubscription? _telemSub;
  StreamSubscription? _batchWatchSub;
  StreamSubscription? _settingsSub;
  Timer? _tickerTimer;
  Timer? _hitAnimationTimer;

  int? _lastRawHardwareCount;
  final List<DateTime> _recentHitTimestamps = [];

  ProductionCubit({
    required this.productionRepo,
    required this.webSocketRepo,
    required this.audioService,
    required this.settingsCubit,
  }) : super(ProductionState.initial(
          defaultBoxCapacity: settingsCubit.state.defaultBoxCapacity,
        )) {
    _init();
  }

  void _init() {
    _loadInitialData();

    // Inscrição nas streams do Repositório WebSocket
    _statusSub = webSocketRepo.connectionStatusStream.listen((status) {
      emit(state.copyWith(connectionStatus: status));
    });

    _errorSub = webSocketRepo.errorStream.listen((err) {
      emit(state.copyWith(
        connectionErrorMessage: err,
        clearConnectionError: err == null,
      ));
    });

    _hitSub = webSocketRepo.hitStream.listen(_handleHit);
    _telemSub = webSocketRepo.telemetryStream.listen(_handleTelemetry);

    // Observa mudanças no lote ativo do Drift
    _batchWatchSub = productionRepo.watchActiveBatch().listen((batch) {
      emit(state.copyWith(
        activeBatch: batch,
        clearActiveBatch: batch == null,
      ));
    });

    // Observa mudanças nas configurações (ex: som habilitado)
    _settingsSub = settingsCubit.stream.listen((settings) {
      audioService.eggSoundEnabled = settings.eggSoundEnabled;
      if (settings.defaultBoxCapacity != state.boxCapacity) {
        emit(state.copyWith(boxCapacity: settings.defaultBoxCapacity));
      }
    });

    // Ticker de 1 segundo para atualização de ovos/minuto
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  Future<void> _loadInitialData() async {
    try {
      final products = await productionRepo.getActiveProducts();
      final activeBatch = await productionRepo.getActiveBatch();
      emit(state.copyWith(
        availableProducts: products,
        activeBatch: activeBatch,
        boxCapacity: activeBatch != null && activeBatch.unitWeightGrams >= 500
            ? 40
            : settingsCubit.state.defaultBoxCapacity,
      ));
    } catch (e) {
      debugPrint('Erro ao carregar dados iniciais de produção: $e');
    }
  }

  void _handleHit(HitFrame frame) {
    audioService.playEggHit();
    _processCountUpdate(frame.eggCount, isDirectHit: true);
  }

  void _handleTelemetry(TelemetryFrame frame) {
    if (frame.uptimeMs != state.uptimeMs) {
      emit(state.copyWith(uptimeMs: frame.uptimeMs));
    }
    _processCountUpdate(frame.eggCount, isDirectHit: false);
  }

  /// Escudo anti-reboot e cálculo diferencial de pulsos
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
      // Queda de energia / reboot do ESP32 detectado (rawHardwareCount < _lastRawHardwareCount)
      debugPrint('ESP32 Reboot detectado: anterior=$_lastRawHardwareCount, novo=$rawHardwareCount');
      delta = rawHardwareCount > 0 ? rawHardwareCount : (isDirectHit ? 1 : 0);
    }

    _lastRawHardwareCount = rawHardwareCount;

    if (delta > 0) {
      _applyCountDelta(delta, rawHardwareCount: rawHardwareCount, now: now);
    }
  }

  void _applyCountDelta(int delta, {required int rawHardwareCount, required DateTime now}) {
    _recentHitTimestamps.add(now);
    _cleanupOldHits(now);

    final newDailyTotal = (state.dailyTotalEggs + delta).clamp(0, 9999999);
    final totalInBox = state.currentBoxCount + delta;
    int newBoxCount = totalInBox;
    int completedIncrement = 0;
    bool justCompleted = false;

    if (totalInBox >= state.boxCapacity) {
      completedIncrement = totalInBox ~/ state.boxCapacity;
      newBoxCount = totalInBox % state.boxCapacity;
      justCompleted = true;
      audioService.playBoxCompleted();
    }

    _hitAnimationTimer?.cancel();
    _hitAnimationTimer = Timer(const Duration(milliseconds: 300), () {
      if (!isClosed) {
        emit(state.copyWith(isHitAnimating: false, isBoxJustCompleted: false));
      }
    });

    // Se houver lote ativo e em progresso, incrementa e persiste no Drift
    final batch = state.activeBatch;
    if (batch != null && batch.status.isInProgress) {
      final newGross = batch.grossProducedCount + delta;
      productionRepo.updateBatchProgress(
        batchId: batch.id,
        grossProducedCount: newGross,
      );
    }

    emit(state.copyWith(
      lastRawHardwareCount: rawHardwareCount,
      dailyTotalEggs: newDailyTotal,
      currentBoxCount: newBoxCount,
      completedBoxesCount: state.completedBoxesCount + completedIncrement,
      isHitAnimating: true,
      isBoxJustCompleted: justCompleted,
      lastHitTime: now,
      eggsPerMinute: _calculateEggsPerMinute(now),
    ));
  }

  /// Incremento manual (+1) pelo operador
  void incrementManual() {
    audioService.playEggHit();
    final now = DateTime.now();
    _recentHitTimestamps.add(now);
    _cleanupOldHits(now);
    final fakeRaw = (state.lastRawHardwareCount ?? 0) + 1;
    _applyCountDelta(1, rawHardwareCount: fakeRaw, now: now);
  }

  /// Decremento manual (-1) para desfazer registro acidental
  void decrementManual() {
    audioService.playEggUndo();
    if (state.currentBoxCount > 0) {
      emit(state.copyWith(
        currentBoxCount: state.currentBoxCount - 1,
        dailyTotalEggs: (state.dailyTotalEggs > 0) ? state.dailyTotalEggs - 1 : 0,
      ));
    } else if (state.completedBoxesCount > 0) {
      emit(state.copyWith(
        completedBoxesCount: state.completedBoxesCount - 1,
        currentBoxCount: state.boxCapacity - 1,
        dailyTotalEggs: (state.dailyTotalEggs > 0) ? state.dailyTotalEggs - 1 : 0,
      ));
    }
  }

  /// Inicia um novo lote de produção no Drift
  Future<void> startBatch(String productId) async {
    try {
      final currentHardwareCount = state.lastRawHardwareCount ?? 0;
      await productionRepo.startBatch(
        productId: productId,
        initialHardwareCount: currentHardwareCount,
      );
      final product = await productionRepo.getProductById(productId);
      if (product != null) {
        emit(state.copyWith(
          boxCapacity: product.defaultBoxCapacity,
          clearActionError: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(actionErrorMessage: 'Falha ao iniciar lote: $e'));
    }
  }

  /// Pausa o lote ativo
  Future<void> pauseBatch() async {
    final batch = state.activeBatch;
    if (batch == null) return;
    try {
      await productionRepo.pauseBatch(batch.id);
    } catch (e) {
      emit(state.copyWith(actionErrorMessage: 'Falha ao pausar lote: $e'));
    }
  }

  /// Retoma o lote ativo
  Future<void> resumeBatch() async {
    final batch = state.activeBatch;
    if (batch == null) return;
    try {
      await productionRepo.resumeBatch(batch.id);
    } catch (e) {
      emit(state.copyWith(actionErrorMessage: 'Falha ao retomar lote: $e'));
    }
  }

  /// Finaliza o lote ativo
  Future<void> finishBatch() async {
    final batch = state.activeBatch;
    if (batch == null) return;
    try {
      await productionRepo.finishBatch(batch.id);
    } catch (e) {
      emit(state.copyWith(actionErrorMessage: 'Falha ao finalizar lote: $e'));
    }
  }

  /// Registra estorno / descarte com justificativa para auditoria
  Future<void> registerAdjustment({
    required AdjustmentReason reason,
    required int quantity,
    String? customNote,
  }) async {
    final batch = state.activeBatch;
    if (batch == null) {
      emit(state.copyWith(actionErrorMessage: 'Nenhum lote ativo para lançar descarte'));
      return;
    }

    try {
      await productionRepo.addAdjustment(
        batchId: batch.id,
        reason: reason,
        deltaQuantity: -quantity.abs(),
        customNote: customNote,
      );
    } catch (e) {
      emit(state.copyWith(actionErrorMessage: 'Falha ao registrar descarte: $e'));
    }
  }

  /// Altera capacidade da caixa (40 ou 50)
  void setBoxCapacity(int capacity) {
    if (capacity <= 0 || capacity == state.boxCapacity) return;
    emit(state.copyWith(boxCapacity: capacity));
    settingsCubit.updateDefaultBoxCapacity(capacity);
  }

  /// Zera contagem da caixa atual sem alterar o total do dia
  void resetCurrentBox() {
    emit(state.copyWith(currentBoxCount: 0));
  }

  /// Zera total do dia
  void resetDailyTotal() {
    emit(state.copyWith(
      dailyTotalEggs: 0,
      completedBoxesCount: 0,
      currentBoxCount: 0,
    ));
  }

  void _onTick() {
    final now = DateTime.now();
    _cleanupOldHits(now);
    emit(state.copyWith(eggsPerMinute: _calculateEggsPerMinute(now)));
  }

  void _cleanupOldHits(DateTime now) {
    _recentHitTimestamps.removeWhere((time) => now.difference(time).inSeconds > 60);
  }

  double _calculateEggsPerMinute(DateTime now) {
    if (_recentHitTimestamps.isEmpty) return 0.0;
    return _recentHitTimestamps.length.toDouble();
  }

  @override
  Future<void> close() {
    _statusSub?.cancel();
    _errorSub?.cancel();
    _hitSub?.cancel();
    _telemSub?.cancel();
    _batchWatchSub?.cancel();
    _settingsSub?.cancel();
    _tickerTimer?.cancel();
    _hitAnimationTimer?.cancel();
    return super.close();
  }
}
