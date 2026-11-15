import 'dart:async';
import 'dart:math';

import 'package:gm_fabrica_monitoramento/src/data/local/daos/freezer_dao.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/door_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/freezer_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/telemetry_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/engine/freezer_adaptive_engine.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_feedback_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_live_state.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_status_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/data/production_repository.dart';
import 'package:gm_fabrica_monitoramento/src/utils/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class FreezerRepository {
  final FreezerDao _freezerDao;
  final WebsocketService _wsService;
  final ProductionRepository _productionRepo;
  final FreezerAdaptiveEngine _engine;

  StreamSubscription? _wsSubscription;
  Timer? _tickerTimer;

  final Map<String, FreezerLiveState> _freezers = {};
  final Map<String, DateTime> _doorOpenSince = {};
  final Map<String, double> _tempWhenOpened = {};
  final Map<String, double> _baselineTempBeforeLoad = {};
  final Map<String, int> _executedSecondsInCycle = {};

  final _freezersStreamController =
      StreamController<Map<String, FreezerLiveState>>.broadcast();
  final _cycleReadyController = StreamController<String>.broadcast();
  final _doorAlarmController = StreamController<String>.broadcast();

  static const int _maxHistoryPoints = 60;
  final int doorCriticalSeconds;
  final int inspectionThresholdSeconds;

  FreezerRepository({
    required this._freezerDao,
    required this._wsService,
    required this._productionRepo,
    this._engine = const FreezerAdaptiveEngine(),
    this.doorCriticalSeconds = 60,
    this.inspectionThresholdSeconds = 12,
  }) {
    _initDefaultFreezers();
    _startTicker();
    _listenWebsocket();
    _restoreActiveCycles();
  }

  Stream<Map<String, FreezerLiveState>> get freezersStream =>
      _freezersStreamController.stream;
  Stream<String> get cycleReadyStream => _cycleReadyController.stream;
  Stream<String> get doorAlarmStream => _doorAlarmController.stream;

  Map<String, FreezerLiveState> get currentFreezers =>
      Map.unmodifiable(_freezers);

  FreezerLiveState? getFreezer(String freezerId) => _freezers[freezerId];

  void _initDefaultFreezers() {
    _freezers['f1'] = const FreezerLiveState(
      freezerId: 'f1',
      name: 'Freezer 1 (Câmara)',
      currentTemp: 4.0,
      isDoorOpen: false,
      isSensorOk: true,
      status: FreezerStatusEnum.idle,
      expectedDurationSeconds: 1200,
      remainingSeconds: 1200,
      calibratedBaseSeconds: 1200,
    );

    _freezers['f2'] = const FreezerLiveState(
      freezerId: 'f2',
      name: 'Freezer 2 (Congelamento)',
      currentTemp: -18.0,
      isDoorOpen: false,
      isSensorOk: true,
      status: FreezerStatusEnum.idle,
      expectedDurationSeconds: 900,
      remainingSeconds: 900,
      calibratedBaseSeconds: 900,
    );

    _emitState();
  }

  Future<void> _restoreActiveCycles() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null;
    }

    for (final id in ['f1', 'f2']) {
      final savedUnload = prefs?.getInt('freezer_${id}_unload_sec');
      final savedReload = prefs?.getInt('freezer_${id}_reload_sec');
      final savedTarget = prefs?.getInt('freezer_${id}_target_sec');

      // 1. Carrega calibração/tempo base salvo
      final calResult = await _freezerDao.getCalibration(id);
      final current = _freezers[id];
      if (current != null) {
        final cal = calResult.valueOrNull;
        final resolvedBase =
            savedTarget ??
            cal?.calibratedDurationSeconds ??
            current.calibratedBaseSeconds;

        _freezers[id] = current.copyWith(
          unloadMinSeconds: savedUnload ?? current.unloadMinSeconds,
          reloadMinSeconds: savedReload ?? current.reloadMinSeconds,
          calibratedBaseSeconds: resolvedBase,
          expectedDurationSeconds: resolvedBase,
          remainingSeconds: resolvedBase,
          isCalibrated: (cal?.sampleCount ?? 0) > 0,
        );
      }

      // 2. Restaura ciclo ativo se houver
      final cycleResult = await _freezerDao.getActiveCoolingCycle(id);
      if (cycleResult.isOk && cycleResult.valueOrThrow != null) {
        final cycle = cycleResult.valueOrThrow!;
        final elapsed = DateTime.now().difference(cycle.startedAt).inSeconds;
        final remaining = max(0, cycle.expectedDurationSeconds - elapsed);
        final afterCal = _freezers[id];
        if (afterCal != null) {
          _freezers[id] = afterCal.copyWith(
            status: remaining == 0
                ? FreezerStatusEnum.ready
                : FreezerStatusEnum.cooling,
            expectedDurationSeconds: cycle.expectedDurationSeconds,
            remainingSeconds: remaining,
            activeCycleId: cycle.id,
            baselineTemp: cycle.baselineTemp,
            peakTemp: cycle.initialPeakTemp,
            accumulatedDoorOpenSeconds: cycle.accumulatedDoorOpenSeconds,
            accumulatedPenaltySeconds: cycle.accumulatedPenaltySeconds,
            doorOpenCount: cycle.doorOpenCount,
          );
          _executedSecondsInCycle[id] = elapsed;
        }
      }
    }
    _emitState();
  }

  void _listenWebsocket() {
    _wsSubscription = _wsService.rawDataStream.listen((data) {
      if (data is TelemetryRawData) {
        for (final f in data.freezers) {
          _handleFreezerRaw(f);
        }
      } else if (data is FreezerRawData) {
        _handleFreezerRaw(data);
      } else if (data is DoorRawData) {
        _handleDoorRaw(data);
      }
    });
  }

  void _handleFreezerRaw(FreezerRawData raw) {
    final now = DateTime.now();
    final prev = _freezers[raw.id] ??
        FreezerLiveState(
          freezerId: raw.id,
          name: raw.id == 'f1' ? 'Freezer 1 (Câmara)' : 'Freezer 2',
          currentTemp: raw.temp,
          isDoorOpen: raw.isDoorOpen,
          isSensorOk: raw.isSensorOk,
          status: FreezerStatusEnum.idle,
          expectedDurationSeconds: 1200,
          remainingSeconds: 1200,
        );

    final doorChanged = prev.isDoorOpen != raw.isDoorOpen;

    // Atualiza histórico de temperatura
    final history = List<({DateTime timestamp, double temperature})>.from(
      prev.temperatureHistory,
    );
    history.add((timestamp: now, temperature: raw.temp));
    if (history.length > _maxHistoryPoints) history.removeAt(0);

    final updatedPeak = (prev.isDoorOpen || prev.peakTemp != null)
        ? max(prev.peakTemp ?? raw.temp, raw.temp)
        : prev.peakTemp;

    var updated = prev.copyWith(
      currentTemp: raw.temp,
      baselineTemp: prev.baselineTemp ?? raw.temp,
      peakTemp: updatedPeak,
      isDoorOpen: raw.isDoorOpen,
      isSensorOk: raw.isSensorOk,
      temperatureHistory: history,
    );

    if (doorChanged) {
      updated = _handleDoorTransition(updated, raw.isDoorOpen, raw.temp, now);
    }

    _freezers[raw.id] = updated;
    _emitState();
  }

  void _handleDoorRaw(DoorRawData door) {
    final freezerId = 'f${door.freezerId}';
    final current = _freezers[freezerId];
    if (current == null) return;

    if (current.isDoorOpen != door.isOpen) {
      final now = DateTime.now();
      final updated = _handleDoorTransition(
        current,
        door.isOpen,
        current.currentTemp,
        now,
      );
      _freezers[freezerId] = updated;
      _emitState();
    }
  }

  FreezerLiveState _handleDoorTransition(
    FreezerLiveState state,
    bool isNowOpen,
    double temp,
    DateTime now,
  ) {
    final id = state.freezerId;
    final transitions =
        List<({DateTime timestamp, bool isOpen, double temperature})>.from(
          state.doorTransitions,
        )..add((timestamp: now, isOpen: isNowOpen, temperature: temp));
    if (transitions.length > 10) transitions.removeAt(0);

    if (isNowOpen) {
      // Porta acabou de ABRIR
      _doorOpenSince[id] = now;
      _tempWhenOpened[id] = temp;

      if (state.status == FreezerStatusEnum.idle) {
        // Grava temperatura basal antes do carregamento
        _baselineTempBeforeLoad[id] = temp;
      }

      if (state.status == FreezerStatusEnum.cooling) {
        return state.copyWith(
          isDoorOpen: true,
          status: FreezerStatusEnum.doorOpen,
          baselineTemp: state.baselineTemp ?? temp,
          lastDoorOpenTemp: temp,
          peakTemp: max(state.peakTemp ?? temp, temp),
          doorTransitions: transitions,
        );
      }

      return state.copyWith(
        isDoorOpen: true,
        baselineTemp: state.baselineTemp ?? temp,
        lastDoorOpenTemp: temp,
        peakTemp: temp,
        doorTransitions: transitions,
      );
    } else {
      // Porta acabou de FECHAR
      final openedAt = _doorOpenSince[id] ?? now;
      final openSeconds = now.difference(openedAt).inSeconds;
      final openedTemp =
          _tempWhenOpened[id] ?? state.lastDoorOpenTemp ?? temp;
      final tempRise = max(0.0, temp - openedTemp);
      final recordedPeak = max(state.peakTemp ?? temp, temp);

      _doorOpenSince.remove(id);
      _tempWhenOpened.remove(id);

      // CASO 1: Estava OCIOSO (IDLE) -> Avalia se foi carregamento de formas
      if (state.status == FreezerStatusEnum.idle) {
        final isInspection = _engine.isInspectionOnly(
          doorOpenSeconds: openSeconds,
          inspectionThresholdSeconds: inspectionThresholdSeconds,
        );

        // Se a porta ficou aberta tempo suficiente para carregamento (> limiar de inspeção)
        if (!isInspection) {
          final baseline = _baselineTempBeforeLoad[id] ?? openedTemp;
          final peakTemp = recordedPeak;

          // Inicia ciclo automático inteligente!
          _startAdaptiveCycleInternal(
            freezerId: id,
            baselineTemp: baseline,
            peakTemp: peakTemp,
          );

          return state.copyWith(
            isDoorOpen: false,
            baselineTemp: baseline,
            peakTemp: peakTemp,
            lastDoorOpenTemp: openedTemp,
            lastDoorCloseTemp: temp,
            doorTransitions: transitions,
          );
        }

        return state.copyWith(
          isDoorOpen: false,
          baselineTemp: state.baselineTemp ?? openedTemp,
          peakTemp: recordedPeak,
          lastDoorOpenTemp: openedTemp,
          lastDoorCloseTemp: temp,
          doorTransitions: transitions,
        );
      }

      // CASO 2: Estava em RESFRIAMENTO (COOLING ou DOOR_OPEN) -> Abertura antes da hora!
      if (state.status == FreezerStatusEnum.cooling ||
          state.status == FreezerStatusEnum.doorOpen) {
        // Se ficou aberta tempo de remoção + novo abastecimento (>= reloadMinSeconds), reinicia o ciclo!
        if (openSeconds >= state.reloadMinSeconds) {
          _startAdaptiveCycleInternal(
            freezerId: id,
            baselineTemp: state.baselineTemp ?? openedTemp,
            peakTemp: recordedPeak,
          );
          return state.copyWith(
            isDoorOpen: false,
            status: FreezerStatusEnum.cooling,
            peakTemp: recordedPeak,
            lastDoorOpenTemp: openedTemp,
            lastDoorCloseTemp: temp,
            doorTransitions: transitions,
          );
        }

        // Aplica penalidade silenciosa proporcional à perda térmica
        final penaltySeconds = _engine.calculateDoorPenalty(
          doorOpenSeconds: openSeconds,
          tempRise: tempRise,
        );

        final newRemaining = state.remainingSeconds + penaltySeconds;
        final newExpected = state.expectedDurationSeconds + penaltySeconds;
        final newAccPenalty =
            state.accumulatedPenaltySeconds + penaltySeconds;
        final newAccDoorOpen = state.accumulatedDoorOpenSeconds + openSeconds;
        final newDoorOpenCount = state.doorOpenCount + 1;

        if (state.activeCycleId != null) {
          _freezerDao.updateCoolingCycleMetrics(
            cycleId: state.activeCycleId!,
            accumulatedDoorOpenSeconds: newAccDoorOpen,
            accumulatedPenaltySeconds: newAccPenalty,
            doorOpenCount: newDoorOpenCount,
          );
        }

        return state.copyWith(
          isDoorOpen: false,
          status: FreezerStatusEnum.cooling,
          expectedDurationSeconds: newExpected,
          remainingSeconds: newRemaining,
          accumulatedPenaltySeconds: newAccPenalty,
          accumulatedDoorOpenSeconds: newAccDoorOpen,
          doorOpenCount: newDoorOpenCount,
          peakTemp: recordedPeak,
          lastDoorOpenTemp: openedTemp,
          lastDoorCloseTemp: temp,
          doorTransitions: transitions,
        );
      }

      // CASO 3: Estava PRONTO (READY) -> Avalia tempo de porta aberta!
      if (state.status == FreezerStatusEnum.ready) {
        // 3A. Abertura curta (< unloadMinSeconds, ex: 15s): Apenas verificação -> Ainda está mole!
        if (openSeconds > 0 && openSeconds < state.unloadMinSeconds) {
          final extensionSec = _engine.immediateExtensionSeconds(
            feedback: FreezerFeedbackEnum.soft,
          );
          final penaltySec = _engine.calculateDoorPenalty(
            doorOpenSeconds: openSeconds,
            tempRise: tempRise,
          );
          final extraSec = extensionSec + penaltySec;
          return state.copyWith(
            isDoorOpen: false,
            status: FreezerStatusEnum.cooling,
            expectedDurationSeconds: state.expectedDurationSeconds + extraSec,
            remainingSeconds: extraSec,
            accumulatedPenaltySeconds:
                state.accumulatedPenaltySeconds + penaltySec,
            accumulatedDoorOpenSeconds:
                state.accumulatedDoorOpenSeconds + openSeconds,
            doorOpenCount: state.doorOpenCount + 1,
            lastFeedback: FreezerFeedbackEnum.soft,
            peakTemp: recordedPeak,
            lastDoorOpenTemp: openedTemp,
            lastDoorCloseTemp: temp,
            doorTransitions: transitions,
          );
        }

        // 3B. Abertura longa (>= reloadMinSeconds, ex: >= 60s): Retirou tudo e já abasteceu novo lote!
        if (openSeconds >= state.reloadMinSeconds) {
          unawaited(recordFeedback(id, FreezerFeedbackEnum.autoOk));
          unawaited(
            _startAdaptiveCycleInternal(
              freezerId: id,
              baselineTemp: state.baselineTemp ?? openedTemp,
              peakTemp: recordedPeak,
            ),
          );
          return state.copyWith(
            isDoorOpen: false,
            status: FreezerStatusEnum.cooling,
            peakTemp: recordedPeak,
            lastDoorOpenTemp: openedTemp,
            lastDoorCloseTemp: temp,
            doorTransitions: transitions,
          );
        }

        // 3C. Retirada das formas (entre unloadMinSeconds e reloadMinSeconds, ex: 30s..59s)
        // Mostra prompt de feedback por 30s (se sumir sozinho = estava tudo bem -> vai para IDLE)
        return state.copyWith(
          isDoorOpen: false,
          status: FreezerStatusEnum.feedbackPending,
          feedbackCountdownSeconds: 30,
          peakTemp: recordedPeak,
          lastDoorOpenTemp: openedTemp,
          lastDoorCloseTemp: temp,
          doorTransitions: transitions,
        );
      }

      return state.copyWith(
        isDoorOpen: false,
        peakTemp: recordedPeak,
        lastDoorOpenTemp: openedTemp,
        lastDoorCloseTemp: temp,
        doorTransitions: transitions,
      );
    }
  }

  void _startTicker() {
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      bool changed = false;
      final now = DateTime.now();

      for (final entry in _freezers.entries) {
        final id = entry.key;
        var s = entry.value;

        // Alerta sonoro de porta aberta há tempo crítico
        if (s.isDoorOpen && _doorOpenSince[id] != null) {
          final openSec = now.difference(_doorOpenSince[id]!).inSeconds;
          if (openSec >= doorCriticalSeconds && !_doorAlarmController.isClosed) {
            _doorAlarmController.add(id);
          }
        }

        // Ticker contínuo (sem pausa na porta e continua contando o tempo extra após atingir o alvo)
        if (s.status == FreezerStatusEnum.cooling ||
            s.status == FreezerStatusEnum.doorOpen ||
            s.status == FreezerStatusEnum.ready) {
          final newElapsed =
              (_executedSecondsInCycle[id] ?? s.elapsedSeconds) + 1;
          _executedSecondsInCycle[id] = newElapsed;
          final rem = max(0, s.expectedDurationSeconds - newElapsed);

          if (s.status == FreezerStatusEnum.cooling && rem == 0) {
            s = s.copyWith(
              elapsedSeconds: newElapsed,
              remainingSeconds: 0,
              status: FreezerStatusEnum.ready,
            );
            if (!_cycleReadyController.isClosed) {
              _cycleReadyController.add(id);
            }
          } else {
            s = s.copyWith(
              elapsedSeconds: newElapsed,
              remainingSeconds: rem,
            );
          }
          _freezers[id] = s;
          changed = true;
        } else if (s.status == FreezerStatusEnum.feedbackPending) {
          // Contagem regressiva do feedback (tolerância de 30s -> auto OK)
          final cd = s.feedbackCountdownSeconds ?? 30;
          if (cd <= 1) {
            // Auto-resolução silenciosa: silêncio = lote OK!
            recordFeedback(id, FreezerFeedbackEnum.autoOk);
            changed = true;
          } else {
            s = s.copyWith(feedbackCountdownSeconds: cd - 1);
            _freezers[id] = s;
            changed = true;
          }
        }
      }

      if (changed) _emitState();
    });
  }

  Future<void> _startAdaptiveCycleInternal({
    required String freezerId,
    required double baselineTemp,
    required double peakTemp,
  }) async {
    final current = _freezers[freezerId];
    if (current == null) return;

    final activeBatch = _productionRepo.currentActiveBatch;
    final baseSeconds = current.calibratedBaseSeconds;

    final startRes = await _freezerDao.startCoolingCycle(
      batchId: activeBatch?.id,
      freezerId: freezerId,
      expectedSeconds: baseSeconds,
      baselineTemp: baselineTemp,
      initialPeakTemp: peakTemp,
    );

    final cycleId = startRes.valueOrNull;

    _executedSecondsInCycle[freezerId] = 0;
    _freezers[freezerId] = current.copyWith(
      status: FreezerStatusEnum.cooling,
      expectedDurationSeconds: baseSeconds,
      remainingSeconds: baseSeconds,
      elapsedSeconds: 0,
      baselineTemp: baselineTemp,
      peakTemp: peakTemp,
      activeCycleId: cycleId,
      accumulatedPenaltySeconds: 0,
      accumulatedDoorOpenSeconds: 0,
      doorOpenCount: 0,
      clearFeedbackCountdown: true,
      calibratedBaseSeconds: baseSeconds,
    );

    _emitState();
  }

  /// Inicia manualmente um ciclo para o freezer especificado
  Future<void> startManualCycle(String freezerId) async {
    final current = _freezers[freezerId];
    if (current == null) return;

    await _startAdaptiveCycleInternal(
      freezerId: freezerId,
      baselineTemp: current.currentTemp,
      peakTemp: current.currentTemp,
    );
  }

  /// Marca manualmente que os ovos já estão prontos ("Pronto"), encerrando o ciclo
  /// e usando o tempo real corrido (seja antes ou depois do planejado) para calibrar o próximo ciclo.
  Future<void> markBatchReadyAndCalibrate(String freezerId) async {
    final current = _freezers[freezerId];
    if (current == null || current.status == FreezerStatusEnum.idle) return;

    await recordFeedback(freezerId, FreezerFeedbackEnum.onPoint);
  }

  /// Registra o feedback do operador ('No Ponto', 'Ainda Mole', 'Muito Gelado')
  Future<void> recordFeedback(
    String freezerId,
    FreezerFeedbackEnum feedback,
  ) async {
    final current = _freezers[freezerId];
    if (current == null) return;

    final activeBatch = _productionRepo.currentActiveBatch;
    final productId = activeBatch?.product.id;
    final executedSeconds =
        (_executedSecondsInCycle[freezerId] ?? current.elapsedSeconds) > 0
            ? (_executedSecondsInCycle[freezerId] ?? current.elapsedSeconds)
            : current.expectedDurationSeconds;

    // 1. Caso 'Ainda Mole': Extensão Imediata de segurança (+3 min)
    if (feedback == FreezerFeedbackEnum.soft) {
      final extensionSec = _engine.immediateExtensionSeconds(feedback: feedback);

      // Atualiza calibração futura
      final newCalibrated = _engine.adaptCalibration(
        currentCalibratedSeconds: current.calibratedBaseSeconds,
        executedEffectiveSeconds: executedSeconds + extensionSec,
        feedback: feedback,
      );

      await _freezerDao.upsertCalibration(
        freezerId: freezerId,
        productId: productId,
        calibratedDurationSeconds: newCalibrated,
        lastFeedback: feedback.code,
      );

      // Reabre ciclo com tempo extra imediato!
      _freezers[freezerId] = current.copyWith(
        status: FreezerStatusEnum.cooling,
        expectedDurationSeconds: current.expectedDurationSeconds + extensionSec,
        remainingSeconds: extensionSec,
        elapsedSeconds: executedSeconds,
        clearFeedbackCountdown: true,
        lastFeedback: feedback,
        calibratedBaseSeconds: newCalibrated,
        isCalibrated: true,
      );

      _emitState();
      return;
    }

    // 2. Finaliza ciclo no SQLite
    if (current.activeCycleId != null) {
      await _freezerDao.finishCoolingCycle(
        cycleId: current.activeCycleId!,
        actualSeconds: executedSeconds,
        accumulatedDoorOpenSeconds: current.accumulatedDoorOpenSeconds,
        accumulatedPenaltySeconds: current.accumulatedPenaltySeconds,
        doorOpenCount: current.doorOpenCount,
        feedback: feedback.code,
      );
    }

    // 3. Atualiza calibração em malha fechada para os próximos lotes (usando o tempo real corrido)
    final newCalibrated = _engine.adaptCalibration(
      currentCalibratedSeconds: current.calibratedBaseSeconds,
      executedEffectiveSeconds: executedSeconds,
      feedback: feedback,
    );

    await _freezerDao.upsertCalibration(
      freezerId: freezerId,
      productId: productId,
      calibratedDurationSeconds: newCalibrated,
      lastFeedback: feedback.code,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('freezer_${freezerId}_target_sec', newCalibrated);
    } catch (_) {}

    // 4. Retorna freezer ao estado IDLE com o novo tempo calibrado pronto para o próximo ciclo
    _executedSecondsInCycle.remove(freezerId);
    _freezers[freezerId] = current.copyWith(
      status: FreezerStatusEnum.idle,
      remainingSeconds: newCalibrated,
      expectedDurationSeconds: newCalibrated,
      elapsedSeconds: 0,
      clearFeedbackCountdown: true,
      clearActiveCycleId: true,
      lastFeedback: feedback,
      calibratedBaseSeconds: newCalibrated,
      isCalibrated: true,
    );

    _emitState();
  }

  /// Cancela o ciclo em andamento (caso o operador tenha disparado sem querer)
  void cancelCycle(String freezerId) {
    final current = _freezers[freezerId];
    if (current == null) return;

    _executedSecondsInCycle.remove(freezerId);
    _freezers[freezerId] = current.copyWith(
      status: FreezerStatusEnum.idle,
      remainingSeconds: current.calibratedBaseSeconds,
      expectedDurationSeconds: current.calibratedBaseSeconds,
      clearFeedbackCountdown: true,
      clearActiveCycleId: true,
    );

    _emitState();
  }

  /// Reinicia manualmente a contagem do ciclo (caso o sensor de porta não tenha detectado a troca)
  Future<void> restartCycle(String freezerId) async {
    final current = _freezers[freezerId];
    if (current == null) return;

    await _startAdaptiveCycleInternal(
      freezerId: freezerId,
      baselineTemp: current.effectiveBaselineTemp,
      peakTemp: current.currentTemp,
    );
  }

  /// Atualiza os parâmetros de tempo de porta do sensor e tempo alvo base (configuráveis no Kiosk ou via Supabase)
  Future<void> updateDoorTimingConfig(
    String freezerId, {
    required int unloadMinSeconds,
    required int reloadMinSeconds,
    int? targetDurationSeconds,
  }) async {
    final current = _freezers[freezerId];
    if (current == null) return;

    final safeUnload = unloadMinSeconds.clamp(10, 300);
    final safeReload = max(safeUnload + 10, reloadMinSeconds.clamp(20, 600));
    final newBase = targetDurationSeconds != null
        ? targetDurationSeconds.clamp(60, 7200)
        : current.calibratedBaseSeconds;

    final isIdle = current.status == FreezerStatusEnum.idle;
    final elapsed = _executedSecondsInCycle[freezerId] ?? current.elapsedSeconds;
    final newExpected = isIdle
        ? newBase
        : newBase + current.accumulatedPenaltySeconds;
    final newRemaining = isIdle
        ? newBase
        : max(0, newExpected - elapsed);

    FreezerStatusEnum updatedStatus = current.status;
    if (current.status == FreezerStatusEnum.cooling && newRemaining == 0) {
      updatedStatus = FreezerStatusEnum.ready;
    } else if (current.status == FreezerStatusEnum.ready && newRemaining > 0) {
      updatedStatus = FreezerStatusEnum.cooling;
    }

    _freezers[freezerId] = current.copyWith(
      status: updatedStatus,
      unloadMinSeconds: safeUnload,
      reloadMinSeconds: safeReload,
      calibratedBaseSeconds: newBase,
      expectedDurationSeconds: newExpected,
      remainingSeconds: newRemaining,
    );

    _emitState();

    // Persiste no SQLite (calibração base) e SharedPreferences
    final activeProductId = _productionRepo.currentActiveBatch?.product.id;
    await _freezerDao.resetCalibration(
      freezerId: freezerId,
      productId: null,
      defaultSeconds: newBase,
    );
    if (activeProductId != null) {
      await _freezerDao.resetCalibration(
        freezerId: freezerId,
        productId: activeProductId,
        defaultSeconds: newBase,
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('freezer_${freezerId}_unload_sec', safeUnload);
      await prefs.setInt('freezer_${freezerId}_reload_sec', safeReload);
      await prefs.setInt('freezer_${freezerId}_target_sec', newBase);
    } catch (_) {
      // Ignora em ambientes de teste sem plugin inicializado
    }
  }

  /// Reseta calibração para valores padrão
  Future<Result<Unit>> resetCalibration(
    String freezerId, {
    String? productId,
    int defaultSeconds = 1200,
  }) async {
    final res = await _freezerDao.resetCalibration(
      freezerId: freezerId,
      productId: productId,
      defaultSeconds: defaultSeconds,
    );

    if (res.isOk) {
      final current = _freezers[freezerId];
      if (current != null) {
        _freezers[freezerId] = current.copyWith(
          calibratedBaseSeconds: defaultSeconds,
          isCalibrated: false,
          expectedDurationSeconds: current.status == FreezerStatusEnum.idle
              ? defaultSeconds
              : current.expectedDurationSeconds,
          remainingSeconds: current.status == FreezerStatusEnum.idle
              ? defaultSeconds
              : current.remainingSeconds,
        );
        _emitState();
      }
    }

    return res;
  }

  void _emitState() {
    if (!_freezersStreamController.isClosed) {
      _freezersStreamController.add(Map.unmodifiable(_freezers));
    }
  }

  void dispose() {
    _wsSubscription?.cancel();
    _tickerTimer?.cancel();
    _freezersStreamController.close();
    _cycleReadyController.close();
    _doorAlarmController.close();
  }
}
