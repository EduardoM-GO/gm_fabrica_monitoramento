import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/freezer_view_data.dart';
import '../../data/models/telemetry_model.dart';
import '../../data/repositories/websocket_repository_impl.dart';
import '../../data/services/audio_service.dart';
import '../../domain/entities/freezer_telemetry_entity.dart';
import '../../domain/repositories/i_freezer_repository.dart';
import '../settings/settings_cubit.dart';
import 'freezer_state.dart';

class _FreezerSnapshot {
  final double temp;
  final int door;
  final int ok;
  final DateTime timestamp;
  final bool wasCritical;

  const _FreezerSnapshot({
    required this.temp,
    required this.door,
    required this.ok,
    required this.timestamp,
    required this.wasCritical,
  });
}

class FreezerCubit extends Cubit<FreezerState> {
  final IFreezerRepository freezerRepo;
  final IWebSocketRepository webSocketRepo;
  final AudioService audioService;
  final SettingsCubit settingsCubit;

  StreamSubscription? _statusSub;
  StreamSubscription? _telemSub;
  StreamSubscription? _settingsSub;
  Timer? _tickerTimer;

  static const int _maxHistoryPoints = 60;
  final Map<String, _FreezerSnapshot> _lastSavedSnapshots = {};
  final Map<String, DateTime> _aboveTempThresholdSince = {};
  final _uuid = const Uuid();

  FreezerCubit({
    required this.freezerRepo,
    required this.webSocketRepo,
    required this.audioService,
    required this.settingsCubit,
  }) : super(FreezerState.initial()) {
    _init();
  }

  void _init() {
    _statusSub = webSocketRepo.connectionStatusStream.listen((status) {
      emit(state.copyWith(connectionStatus: status));
    });

    _telemSub = webSocketRepo.telemetryStream.listen(_handleTelemetry);

    _settingsSub = settingsCubit.stream.listen((settings) {
      audioService.alarmSoundEnabled = settings.alarmSoundEnabled;
    });

    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _handleTelemetry(TelemetryFrame frame) {
    final now = DateTime.now();

    final f1 = frame.freezer1 != null
        ? _computeFreezerState(
            previous: state.freezer1,
            raw: frame.freezer1!,
            freezerId: 'f1',
            defaultName: 'Freezer 1 (Câmara)',
            defaultTargetMinutes: settingsCubit.state.freezer1BaseMinutes,
            tempMaxThreshold: 8.0, // Limite de alerta da câmara de resfriamento
            now: now,
          )
        : state.freezer1;

    final f2 = frame.freezer2 != null
        ? _computeFreezerState(
            previous: state.freezer2,
            raw: frame.freezer2!,
            freezerId: 'f2',
            defaultName: 'Freezer 2 (Congelamento)',
            defaultTargetMinutes: settingsCubit.state.freezer2BaseMinutes,
            tempMaxThreshold: -12.0, // Limite de alerta do freezer de congelamento
            now: now,
          )
        : state.freezer2;

    // Dispara alarme sonoro se algum freezer estiver em estado crítico
    if ((f1 != null && f1.alertLevel.isCritical) ||
        (f2 != null && f2.alertLevel.isCritical)) {
      audioService.playDoorAlarm();
    }

    // Amostragem híbrida no Drift para F1 e F2
    if (frame.freezer1 != null) {
      _checkAndSampleToDrift(
        'f1',
        frame.freezer1!,
        now,
        isCriticalAlert: f1?.alertLevel.isCritical ?? false,
      );
    }
    if (frame.freezer2 != null) {
      _checkAndSampleToDrift(
        'f2',
        frame.freezer2!,
        now,
        isCriticalAlert: f2?.alertLevel.isCritical ?? false,
      );
    }

    emit(state.copyWith(
      freezer1: f1,
      freezer2: f2,
      lastTelemTime: now,
    ));
  }

  FreezerViewData _computeFreezerState({
    required FreezerViewData? previous,
    required FreezerRawData raw,
    required String freezerId,
    required String defaultName,
    required int defaultTargetMinutes,
    required double tempMaxThreshold,
    required DateTime now,
  }) {
    final prev = previous ??
        FreezerViewData(
          id: freezerId,
          name: defaultName,
          currentTemp: raw.temp,
          isProbeOk: raw.isProbeOk,
          isDoorOpen: raw.isDoorOpen,
          baselineTemp: raw.temp,
          doorStateSince: now,
          targetCoolingMinutes: defaultTargetMinutes,
          remainingSeconds: defaultTargetMinutes * 60,
          batchStatus: raw.isDoorOpen
              ? FreezerBatchStatus.doorOpen
              : FreezerBatchStatus.cooling,
          batchStartedAt: now,
        );

    final doorChanged = prev.doorStateSince == null || prev.isDoorOpen != raw.isDoorOpen;
    final doorStateSince = doorChanged ? now : prev.doorStateSince;
    final baselineTemp = doorChanged ? raw.temp : prev.baselineTemp;

    // 1. Alerta de Porta Aberta
    DoorAlertLevel alertLevel = DoorAlertLevel.normal;
    if (raw.isDoorOpen && doorStateSince != null) {
      final openSeconds = now.difference(doorStateSince).inSeconds;
      if (openSeconds >= settingsCubit.state.doorCriticalSeconds) {
        alertLevel = DoorAlertLevel.critical;
      } else if (openSeconds >= settingsCubit.state.doorWarningSeconds) {
        alertLevel = DoorAlertLevel.warning;
      }
    }

    // 2. Alerta imediato se sonda de temperatura rompida ou desconectada (ok == 0)
    if (!raw.isProbeOk) {
      alertLevel = DoorAlertLevel.critical;
    }

    // 3. Alerta de Temperatura Acima do Limite por mais de N minutos consecutivos
    if (raw.temp > tempMaxThreshold) {
      _aboveTempThresholdSince.putIfAbsent(freezerId, () => now);
      final minutesAbove = now.difference(_aboveTempThresholdSince[freezerId]!).inMinutes;
      if (minutesAbove >= 3) {
        alertLevel = DoorAlertLevel.critical;
      }
    } else {
      _aboveTempThresholdSince.remove(freezerId);
    }

    // Histórico de pontos para o gráfico de temperatura
    final updatedHistory = List<TemperaturePoint>.from(prev.history);
    updatedHistory.add(TemperaturePoint(timestamp: now, temperature: raw.temp));
    if (updatedHistory.length > _maxHistoryPoints) {
      updatedHistory.removeAt(0);
    }

    FreezerBatchStatus batchStatus = prev.batchStatus;
    int remainingSeconds = prev.remainingSeconds;
    DateTime? batchStartedAt = prev.batchStartedAt;
    int? feedbackCountdownSeconds = prev.feedbackCountdownSeconds;

    if (doorChanged) {
      if (raw.isDoorOpen) {
        batchStatus = FreezerBatchStatus.doorOpen;
      } else {
        final openDuration = prev.doorStateSince != null
            ? now.difference(prev.doorStateSince!).inSeconds
            : 0;

        if (openDuration >= settingsCubit.state.doorInspectionThresholdSeconds) {
          batchStatus = FreezerBatchStatus.feedbackPending;
          feedbackCountdownSeconds = 30;
          batchStartedAt = now;
          remainingSeconds = prev.targetCoolingMinutes * 60;
        } else {
          if (prev.remainingSeconds <= 0) {
            batchStatus = FreezerBatchStatus.ready;
          } else {
            batchStatus = FreezerBatchStatus.cooling;
            remainingSeconds = prev.remainingSeconds + (openDuration * 2).clamp(10, 120);
          }
        }
      }
    }

    return prev.copyWith(
      currentTemp: raw.temp,
      isProbeOk: raw.isProbeOk,
      isDoorOpen: raw.isDoorOpen,
      doorStateSince: doorStateSince,
      baselineTemp: baselineTemp,
      alertLevel: alertLevel,
      history: updatedHistory,
      batchStatus: batchStatus,
      remainingSeconds: remainingSeconds,
      batchStartedAt: batchStartedAt,
      feedbackCountdownSeconds: feedbackCountdownSeconds,
    );
  }

  /// Política de amostragem híbrida: eventos discretos imediatos e rotina a cada 30s
  void _checkAndSampleToDrift(
    String freezerId,
    FreezerRawData raw,
    DateTime now, {
    required bool isCriticalAlert,
  }) {
    final last = _lastSavedSnapshots[freezerId];
    bool shouldSave = false;
    String reason = 'periodic_30s';

    if (last == null) {
      shouldSave = true;
      reason = 'initial';
    } else if (last.door != raw.door) {
      shouldSave = true;
      reason = 'event_door';
    } else if (last.ok != raw.ok) {
      shouldSave = true;
      reason = 'event_probe';
    } else if (isCriticalAlert && !last.wasCritical) {
      shouldSave = true;
      reason = 'alert_thermal';
    } else if ((raw.temp - last.temp).abs() >= 0.5) {
      shouldSave = true;
      reason = 'delta_temp_0.5';
    } else if (now.difference(last.timestamp).inSeconds >= 30) {
      shouldSave = true;
      reason = 'periodic_30s';
    }

    if (shouldSave) {
      _lastSavedSnapshots[freezerId] = _FreezerSnapshot(
        temp: raw.temp,
        door: raw.door,
        ok: raw.ok,
        timestamp: now,
        wasCritical: isCriticalAlert,
      );

      freezerRepo.recordTelemetryLog(
        FreezerTelemetryLogEntity(
          id: _uuid.v4(),
          freezerId: freezerId,
          temperature: raw.temp,
          isDoorOpen: raw.isDoorOpen,
          isSensorOk: raw.isProbeOk,
          recordedAt: now,
          triggerReason: reason,
          isSynced: false,
        ),
      );
    }
  }

  void _onTick() {
    final now = DateTime.now();

    FreezerViewData? f1 = state.freezer1;
    if (f1 != null) {
      f1 = _tickFreezer(f1, now);
      if (f1.alertLevel.isCritical) {
        audioService.playDoorAlarm();
      }
    }

    FreezerViewData? f2 = state.freezer2;
    if (f2 != null) {
      f2 = _tickFreezer(f2, now);
      if (f2.alertLevel.isCritical) {
        audioService.playDoorAlarm();
      }
    }

    emit(state.copyWith(
      freezer1: f1,
      freezer2: f2,
    ));
  }

  FreezerViewData _tickFreezer(FreezerViewData freezer, DateTime now) {
    if (freezer.batchStatus == FreezerBatchStatus.cooling) {
      final rem = (freezer.remainingSeconds - 1).clamp(0, 99999);
      if (rem == 0) {
        audioService.playFreezerReady();
        return freezer.copyWith(
          remainingSeconds: 0,
          batchStatus: FreezerBatchStatus.ready,
        );
      }
      return freezer.copyWith(remainingSeconds: rem);
    } else if (freezer.batchStatus == FreezerBatchStatus.feedbackPending) {
      if (freezer.feedbackCountdownSeconds != null) {
        final cd = freezer.feedbackCountdownSeconds! - 1;
        if (cd <= 0) {
          return freezer.copyWith(
            clearFeedbackCountdown: true,
            batchStatus: FreezerBatchStatus.cooling,
            lastFeedback: 'No ponto (Automático)',
          );
        }
        return freezer.copyWith(feedbackCountdownSeconds: cd);
      }
    }
    return freezer;
  }

  void recordFreezerFeedback(String freezerId, String feedback) {
    if (freezerId == 'f1' && state.freezer1 != null) {
      emit(state.copyWith(
        freezer1: state.freezer1!.copyWith(
          batchStatus: FreezerBatchStatus.cooling,
          clearFeedbackCountdown: true,
          lastFeedback: feedback,
        ),
      ));
    } else if (freezerId == 'f2' && state.freezer2 != null) {
      emit(state.copyWith(
        freezer2: state.freezer2!.copyWith(
          batchStatus: FreezerBatchStatus.cooling,
          clearFeedbackCountdown: true,
          lastFeedback: feedback,
        ),
      ));
    }
  }

  void toggleSimulatorDoor(int freezerNum) {
    webSocketRepo.toggleSimulatorDoor(freezerNum);
  }

  void startFreezerBatch(String freezerId) {
    final now = DateTime.now();
    if (freezerId == 'f1' && state.freezer1 != null) {
      final target = state.freezer1!.targetCoolingMinutes;
      emit(state.copyWith(
        freezer1: state.freezer1!.copyWith(
          batchStatus: FreezerBatchStatus.cooling,
          remainingSeconds: target * 60,
          batchStartedAt: now,
          clearFeedbackCountdown: true,
        ),
      ));
    } else if (freezerId == 'f2' && state.freezer2 != null) {
      final target = state.freezer2!.targetCoolingMinutes;
      emit(state.copyWith(
        freezer2: state.freezer2!.copyWith(
          batchStatus: FreezerBatchStatus.cooling,
          remainingSeconds: target * 60,
          batchStartedAt: now,
          clearFeedbackCountdown: true,
        ),
      ));
    }
  }

  @override
  Future<void> close() {
    _statusSub?.cancel();
    _telemSub?.cancel();
    _settingsSub?.cancel();
    _tickerTimer?.cancel();
    return super.close();
  }
}
