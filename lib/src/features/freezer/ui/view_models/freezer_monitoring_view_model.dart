import 'dart:async';

import 'package:gm_fabrica_monitoramento/src/data/services/audio_service.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/freezer_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/data/freezer_repository.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_feedback_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_live_state.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_status_enum.dart';
import 'package:gm_fabrica_monitoramento/src/utils/result.dart';
import 'package:signals/signals.dart';

/// Micro-states granulares para um Freezer específico (`f1` ou `f2`).
/// Cada campo visual da UI assina apenas o seu próprio Signal, evitando que
/// o tick de 1s do cronômetro reconstrua botões, cabeçalho, temperatura ou gráfico.
final class FreezerItemSignals {
  final String freezerId;

  late final Signal<FreezerLiveState> rawState;

  // --- Micro-states de Identificação e Vínculo ---
  late final Signal<int> sensorIndex;
  late final Signal<String> name;
  late final Signal<String?> equipmentId;
  late final Signal<String?> equipmentName;
  late final Signal<String> displayHeaderName;
  late final Signal<bool> hasLinkedEquipment;

  // --- Micro-states de Status e Porta ---
  late final Signal<FreezerStatusEnum> status;
  late final Signal<bool> isDoorOpen;
  late final Signal<bool> isSensorOk;
  late final Signal<bool> hasOvertime;

  // --- Micro-states de Tempo e Progresso (atualizam a 1 Hz) ---
  late final Signal<String> elapsedFormatted;
  late final Signal<String> targetFormatted;
  late final Signal<double> progress;
  late final Signal<int> feedbackCountdownSeconds;
  late final Signal<String> currentDoorOpenFormatted;

  // --- Micro-states de Temperatura e Curva Térmica ---
  late final Signal<double> currentTemp;
  late final Signal<String> formattedTemp;
  late final Signal<double> effectiveBaselineTemp;
  late final Signal<double> doorDeltaTemp;
  late final Signal<double> recoveredDegrees;
  late final Signal<int> doorOpenCount;
  late final Signal<int> accumulatedPenaltySeconds;
  late final Signal<List<({DateTime timestamp, double temperature})>>
  temperatureHistory;
  late final Signal<
    List<({DateTime timestamp, bool isOpen, double temperature})>
  >
  doorTransitions;

  // --- Micro-states de Configuração ---
  late final Signal<int> unloadMinSeconds;
  late final Signal<int> reloadMinSeconds;
  late final Signal<int> calibratedBaseSeconds;

  FreezerItemSignals(FreezerLiveState initial) : freezerId = initial.freezerId {
    rawState = signal<FreezerLiveState>(initial);

    sensorIndex = signal<int>(initial.sensorIndex);
    name = signal<String>(initial.name);
    equipmentId = signal<String?>(initial.equipmentId);
    equipmentName = signal<String?>(initial.equipmentName);
    displayHeaderName = signal<String>(initial.displayHeaderName);
    hasLinkedEquipment = signal<bool>(initial.hasLinkedEquipment);

    status = signal<FreezerStatusEnum>(initial.status);
    isDoorOpen = signal<bool>(initial.isDoorOpen);
    isSensorOk = signal<bool>(initial.isSensorOk);
    hasOvertime = signal<bool>(initial.overtimeSeconds > 0);

    elapsedFormatted = signal<String>(initial.elapsedFormatted);
    targetFormatted = signal<String>(initial.targetFormatted);
    progress = signal<double>(initial.progress);
    feedbackCountdownSeconds = signal<int>(
      initial.feedbackCountdownSeconds ?? 30,
    );
    currentDoorOpenFormatted = signal<String>(initial.currentDoorOpenFormatted);

    currentTemp = signal<double>(initial.currentTemp);
    formattedTemp = signal<String>(_formatTemp(initial));
    effectiveBaselineTemp = signal<double>(initial.effectiveBaselineTemp);
    doorDeltaTemp = signal<double>(initial.doorDeltaTemp);
    recoveredDegrees = signal<double>(initial.recoveredDegrees);
    doorOpenCount = signal<int>(initial.doorOpenCount);
    accumulatedPenaltySeconds = signal<int>(initial.accumulatedPenaltySeconds);
    temperatureHistory =
        signal<List<({DateTime timestamp, double temperature})>>(
          initial.temperatureHistory,
        );
    doorTransitions =
        signal<List<({DateTime timestamp, bool isOpen, double temperature})>>(
          initial.doorTransitions,
        );

    unloadMinSeconds = signal<int>(initial.unloadMinSeconds);
    reloadMinSeconds = signal<int>(initial.reloadMinSeconds);
    calibratedBaseSeconds = signal<int>(initial.calibratedBaseSeconds);
  }

  static String _formatTemp(FreezerLiveState s) =>
      s.isSensorOk ? '${s.currentTemp.toStringAsFixed(1)} °C' : '--.- °C';

  /// Atualiza em batch apenas os micro-states cujo valor realmente mudou.
  void update(FreezerLiveState next) {
    batch(() {
      rawState.value = next;

      if (sensorIndex.value != next.sensorIndex) {
        sensorIndex.value = next.sensorIndex;
      }
      if (name.value != next.name) {
        name.value = next.name;
      }
      if (equipmentId.value != next.equipmentId) {
        equipmentId.value = next.equipmentId;
      }
      if (equipmentName.value != next.equipmentName) {
        equipmentName.value = next.equipmentName;
      }
      if (displayHeaderName.value != next.displayHeaderName) {
        displayHeaderName.value = next.displayHeaderName;
      }
      if (hasLinkedEquipment.value != next.hasLinkedEquipment) {
        hasLinkedEquipment.value = next.hasLinkedEquipment;
      }

      if (status.value != next.status) {
        status.value = next.status;
      }
      if (isDoorOpen.value != next.isDoorOpen) {
        isDoorOpen.value = next.isDoorOpen;
      }
      if (isSensorOk.value != next.isSensorOk) {
        isSensorOk.value = next.isSensorOk;
      }
      final nextOvertime = next.overtimeSeconds > 0;
      if (hasOvertime.value != nextOvertime) {
        hasOvertime.value = nextOvertime;
      }

      if (elapsedFormatted.value != next.elapsedFormatted) {
        elapsedFormatted.value = next.elapsedFormatted;
      }
      if (targetFormatted.value != next.targetFormatted) {
        targetFormatted.value = next.targetFormatted;
      }
      if (progress.value != next.progress) {
        progress.value = next.progress;
      }
      final nextCd = next.feedbackCountdownSeconds ?? 30;
      if (feedbackCountdownSeconds.value != nextCd) {
        feedbackCountdownSeconds.value = nextCd;
      }
      if (currentDoorOpenFormatted.value != next.currentDoorOpenFormatted) {
        currentDoorOpenFormatted.value = next.currentDoorOpenFormatted;
      }

      if (currentTemp.value != next.currentTemp) {
        currentTemp.value = next.currentTemp;
      }
      final nextFmtTemp = _formatTemp(next);
      if (formattedTemp.value != nextFmtTemp) {
        formattedTemp.value = nextFmtTemp;
      }
      if (effectiveBaselineTemp.value != next.effectiveBaselineTemp) {
        effectiveBaselineTemp.value = next.effectiveBaselineTemp;
      }
      if (doorDeltaTemp.value != next.doorDeltaTemp) {
        doorDeltaTemp.value = next.doorDeltaTemp;
      }
      if (recoveredDegrees.value != next.recoveredDegrees) {
        recoveredDegrees.value = next.recoveredDegrees;
      }
      if (doorOpenCount.value != next.doorOpenCount) {
        doorOpenCount.value = next.doorOpenCount;
      }
      if (accumulatedPenaltySeconds.value != next.accumulatedPenaltySeconds) {
        accumulatedPenaltySeconds.value = next.accumulatedPenaltySeconds;
      }

      final prevHist = temperatureHistory.value;
      final nextHist = next.temperatureHistory;
      if (!identical(prevHist, nextHist) &&
          (prevHist.length != nextHist.length ||
              (nextHist.isNotEmpty &&
                  prevHist.isNotEmpty &&
                  prevHist.last != nextHist.last))) {
        temperatureHistory.value = nextHist;
      }

      final prevTrans = doorTransitions.value;
      final nextTrans = next.doorTransitions;
      if (!identical(prevTrans, nextTrans) &&
          (prevTrans.length != nextTrans.length ||
              (nextTrans.isNotEmpty &&
                  prevTrans.isNotEmpty &&
                  prevTrans.last != nextTrans.last))) {
        doorTransitions.value = nextTrans;
      }

      if (unloadMinSeconds.value != next.unloadMinSeconds) {
        unloadMinSeconds.value = next.unloadMinSeconds;
      }
      if (reloadMinSeconds.value != next.reloadMinSeconds) {
        reloadMinSeconds.value = next.reloadMinSeconds;
      }
      if (calibratedBaseSeconds.value != next.calibratedBaseSeconds) {
        calibratedBaseSeconds.value = next.calibratedBaseSeconds;
      }
    });
  }
}

final class FreezerMonitoringViewModel {
  final FreezerRepository _repository;
  final AudioService? _audioService;

  // --- Signals Reativos ---
  late final Signal<Map<String, FreezerLiveState>> freezers;
  late final Signal<List<EquipmentModel>> availableEquipments;
  late final Signal<bool> isSyncingEquipments;
  late final Computed<List<FreezerLiveState>> activeFreezers;
  late final Computed<FreezerLiveState?> freezer1;
  late final Computed<FreezerLiveState?> freezer2;
  late final Signal<bool> hasDoorAlarm;

  /// Micro-states dedicados por freezer (`f1`, `f2`) para atualização cirúrgica por campo
  final Map<String, FreezerItemSignals> _itemSignals = {};

  StreamSubscription? _freezersSub;
  StreamSubscription? _equipmentsSub;
  StreamSubscription? _equipmentsLoadingSub;
  StreamSubscription? _startedSub;
  StreamSubscription? _readySub;
  StreamSubscription? _doorToggleSub;
  StreamSubscription? _alarmSub;

  FreezerMonitoringViewModel(
    this._repository, {
    this._audioService,
  }) {
    _initSignals();
    _bindRepositoryStreams();
  }

  /// Retorna o conjunto de micro-states granulares para o freezer [freezerId].
  FreezerItemSignals? itemSignalsOf(String freezerId) =>
      _itemSignals[freezerId];

  void _initSignals() {
    final initialMap = _repository.currentFreezers;
    for (final entry in initialMap.entries) {
      _itemSignals[entry.key] = FreezerItemSignals(entry.value);
    }

    freezers = signal<Map<String, FreezerLiveState>>(initialMap);
    availableEquipments = signal<List<EquipmentModel>>(
      _repository.currentEquipments,
    );
    isSyncingEquipments = signal<bool>(_repository.isSyncingEquipments);

    activeFreezers = computed<List<FreezerLiveState>>(() {
      return freezers.value.values.toList();
    });

    freezer1 = computed<FreezerLiveState?>(() => freezers.value['f1']);
    freezer2 = computed<FreezerLiveState?>(() => freezers.value['f2']);

    hasDoorAlarm = signal<bool>(_computeDoorAlarm(initialMap));
  }

  bool _computeDoorAlarm(Map<String, FreezerLiveState> map) {
    return map.values.any(
      (f) =>
          !f.isSensorOk ||
          (f.isDoorOpen &&
              (f.currentDoorOpenSeconds >= _repository.doorCriticalSeconds ||
                  f.accumulatedDoorOpenSeconds >=
                      _repository.doorCriticalSeconds)),
    );
  }

  void _bindRepositoryStreams() {
    _freezersSub = _repository.freezersStream.listen((data) {
      batch(() {
        freezers.value = data;
        for (final entry in data.entries) {
          final existing = _itemSignals[entry.key];
          if (existing != null) {
            existing.update(entry.value);
          } else {
            _itemSignals[entry.key] = FreezerItemSignals(entry.value);
          }
        }
        final nextAlarm = _computeDoorAlarm(data);
        if (hasDoorAlarm.value != nextAlarm) {
          hasDoorAlarm.value = nextAlarm;
        }
      });
    });

    _equipmentsSub = _repository.availableEquipmentsStream.listen((equipments) {
      availableEquipments.value = equipments;
    });

    _equipmentsLoadingSub = _repository.isSyncingEquipmentsStream.listen((
      loading,
    ) {
      isSyncingEquipments.value = loading;
    });

    _startedSub = _repository.cycleStartedStream.listen((freezerId) {
      _audioService?.playFreezerStarted(freezerId: freezerId);
    });

    _readySub = _repository.cycleReadyStream.listen((freezerId) {
      _audioService?.playFreezerReady(freezerId: freezerId);
    });

    _doorToggleSub = _repository.doorToggleStream.listen((event) {
      if (event.isOpen) {
        _audioService?.playDoorOpened();
      } else {
        _audioService?.playDoorClosed();
      }
    });

    _alarmSub = _repository.doorAlarmStream.listen((freezerId) {
      _audioService?.playDoorAlarm();
    });
  }

  /// Sincroniza sob demanda a lista de equipamentos (`cost_centers`) e vínculos do Supabase
  Future<Result<List<EquipmentModel>>> refreshEquipmentsAndBindings() {
    return _repository.refreshEquipmentsAndBindingsFromSupabase();
  }

  /// Vincula (ou desvincula) um equipamento do Supabase (`cost_centers`) ao sensor (`f1`, `f2`)
  Future<Result<Unit>> bindEquipmentToSensor({
    required String sensorKey,
    required EquipmentModel? equipment,
  }) {
    return _repository.bindEquipmentToSensor(
      sensorKey: sensorKey,
      equipment: equipment,
    );
  }

  /// Registra feedback do operador ('No Ponto', 'Ainda Mole', 'Muito Gelado')
  Future<void> recordFeedback(
    String freezerId,
    FreezerFeedbackEnum feedback,
  ) async {
    await _repository.recordFeedback(freezerId, feedback);
  }

  /// Inicia manualmente um ciclo para o freezer especificado
  Future<void> startManualCycle(String freezerId) async {
    await _repository.startManualCycle(freezerId);
  }

  /// Cancela o ciclo em andamento
  void cancelCycle(String freezerId) {
    _repository.cancelCycle(freezerId);
  }

  /// Reinicia manualmente a contagem do ciclo (caso o sensor de porta falhe)
  Future<void> restartCycle(String freezerId) async {
    await _repository.restartCycle(freezerId);
  }

  /// Marca que os ovos já estão prontos, encerrando o ciclo atual e calibrando o próximo ciclo com o tempo real corrido
  Future<void> markBatchReadyAndCalibrate(String freezerId) async {
    await _repository.markBatchReadyAndCalibrate(freezerId);
  }

  /// Atualiza os tempos de porta, tempo alvo base e opcionalmente o equipamento vinculado
  Future<void> updateDoorTimingConfig(
    String freezerId, {
    required int unloadMinSeconds,
    required int reloadMinSeconds,
    int? targetDurationSeconds,
    EquipmentModel? linkedEquipment,
    bool updateEquipmentBinding = false,
  }) async {
    await _repository.updateDoorTimingConfig(
      freezerId,
      unloadMinSeconds: unloadMinSeconds,
      reloadMinSeconds: reloadMinSeconds,
      targetDurationSeconds: targetDurationSeconds,
      linkedEquipment: linkedEquipment,
      updateEquipmentBinding: updateEquipmentBinding,
    );
  }

  /// Reseta a calibração de um freezer para o valor padrão de fábrica (8 minutos = 480s)
  Future<Result<Unit>> resetCalibration(
    String freezerId, {
    String? productId,
    int defaultSeconds = 480,
  }) async {
    return _repository.resetCalibration(
      freezerId,
      productId: productId,
      defaultSeconds: defaultSeconds,
    );
  }

  void dispose() {
    _freezersSub?.cancel();
    _equipmentsSub?.cancel();
    _equipmentsLoadingSub?.cancel();
    _startedSub?.cancel();
    _readySub?.cancel();
    _doorToggleSub?.cancel();
    _alarmSub?.cancel();
  }
}
