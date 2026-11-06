import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/model/telemetry_model.dart';
import '../../../../data/services/audio_service.dart';
import '../../../../domain/entities/freezer_telemetry_entity.dart';
import '../../../../domain/repositories/i_freezer_repository.dart';
import '../../../../domain/repositories/websocket_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../settings/view_models/settings_viewmodel.dart';
import 'freezer_state.dart';

export 'freezer_state.dart';

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

/// ViewModel managing freezers, cold chambers, and door alarms.
/// Implements the official Flutter MVVM architecture pattern.
class FreezerViewModel extends ChangeNotifier {
  final IFreezerRepository freezerRepo;
  final IWebSocketRepository webSocketRepo;
  final AudioService audioService;
  final SettingsViewModel settingsViewModel;

  FreezerState _state;
  FreezerState get state => _state;

  late final Command1<void, String> startFreezerBatchCommand;
  late final Command1<void, ({String freezerId, String feedback})>
  recordFeedbackCommand;
  late final Command1<void, int> toggleSimulatorDoorCommand;
  late final Command1<void, int> toggleSimulatorProbeCommand;

  StreamSubscription? _statusSub;
  StreamSubscription? _telemSub;
  VoidCallback? _settingsListener;
  Timer? _tickerTimer;

  static const int _maxHistoryPoints = 60;
  final Map<String, _FreezerSnapshot> _lastSavedSnapshots = {};
  final Map<String, DateTime> _aboveTempThresholdSince = {};
  final _uuid = const Uuid();

  FreezerViewModel({
    required this.freezerRepo,
    required this.webSocketRepo,
    required this.audioService,
    required this.settingsViewModel,
  }) : _state = FreezerState.initial() {
    _initCommands();
    _init();
  }

  void _initCommands() {
    startFreezerBatchCommand = Command1((freezerId) async {
      startFreezerBatch(freezerId);
      return const Result.ok(null);
    });
    recordFeedbackCommand = Command1((params) async {
      recordFreezerFeedback(params.freezerId, params.feedback);
      return const Result.ok(null);
    });
    toggleSimulatorDoorCommand = Command1((freezerNumber) async {
      toggleSimulatorDoor(freezerNumber);
      return const Result.ok(null);
    });
    toggleSimulatorProbeCommand = Command1((freezerNumber) async {
      webSocketRepo.toggleSimulatorProbe(freezerNumber);
      return const Result.ok(null);
    });
  }

  void _init() {
    _statusSub = webSocketRepo.connectionStatusStream.listen((status) {
      _state = _state.copyWith(connectionStatus: status);
      notifyListeners();
    });

    _telemSub = webSocketRepo.telemetryStream.listen(_handleTelemetry);

    _settingsListener = () {
      audioService.alarmSoundEnabled = settingsViewModel.alarmSoundEnabled;
    };
    settingsViewModel.addListener(_settingsListener!);

    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _handleTelemetry(TelemetryFrame frame) {
    final now = DateTime.now();

    final f1 = frame.freezer1 != null
        ? _computeFreezerState(
            previous: _state.freezer1,
            raw: frame.freezer1!,
            freezerId: 'f1',
            defaultName: 'Freezer 1 (Câmara)',
            defaultTargetMinutes: settingsViewModel.freezer1BaseMinutes,
            tempMaxThreshold: 8.0,
            now: now,
          )
        : _state.freezer1;

    final f2 = frame.freezer2 != null
        ? _computeFreezerState(
            previous: _state.freezer2,
            raw: frame.freezer2!,
            freezerId: 'f2',
            defaultName: 'Freezer 2 (Congelamento)',
            defaultTargetMinutes: settingsViewModel.freezer2BaseMinutes,
            tempMaxThreshold: -12.0,
            now: now,
          )
        : _state.freezer2;

    // Trigger door alarm sound if any freezer is in critical alert
    if ((f1 != null && f1.alertLevel.isCritical) ||
        (f2 != null && f2.alertLevel.isCritical)) {
      audioService.playDoorAlarm();
    }

    // Hybrid sampling to Drift database
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

    _state = _state.copyWith(freezer1: f1, freezer2: f2, lastTelemTime: now);
    notifyListeners();
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
    final prev =
        previous ??
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

    final doorChanged =
        prev.doorStateSince == null || prev.isDoorOpen != raw.isDoorOpen;
    final doorStateSince = doorChanged ? now : prev.doorStateSince;
    final baselineTemp = doorChanged ? raw.temp : prev.baselineTemp;

    // 1. Door Open Alert
    DoorAlertLevel alertLevel = DoorAlertLevel.normal;
    if (raw.isDoorOpen && doorStateSince != null) {
      final openSeconds = now.difference(doorStateSince).inSeconds;
      if (openSeconds >= settingsViewModel.doorCriticalSeconds) {
        alertLevel = DoorAlertLevel.critical;
      } else if (openSeconds >= settingsViewModel.doorWarningSeconds) {
        alertLevel = DoorAlertLevel.warning;
      }
    }

    // 2. Immediate alert if probe is broken or disconnected
    if (!raw.isProbeOk) {
      alertLevel = DoorAlertLevel.critical;
    }

    // 3. Thermal threshold alert
    if (raw.temp > tempMaxThreshold) {
      _aboveTempThresholdSince.putIfAbsent(freezerId, () => now);
      final minutesAbove = now
          .difference(_aboveTempThresholdSince[freezerId]!)
          .inMinutes;
      if (minutesAbove >= 3) {
        alertLevel = DoorAlertLevel.critical;
      }
    } else {
      _aboveTempThresholdSince.remove(freezerId);
    }

    // History for temperature charts
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

        if (openDuration >= settingsViewModel.doorInspectionThresholdSeconds) {
          batchStatus = FreezerBatchStatus.feedbackPending;
          feedbackCountdownSeconds = 30;
          batchStartedAt = now;
          remainingSeconds = prev.targetCoolingMinutes * 60;
        } else {
          if (prev.remainingSeconds <= 0) {
            batchStatus = FreezerBatchStatus.ready;
          } else {
            batchStatus = FreezerBatchStatus.cooling;
            remainingSeconds =
                prev.remainingSeconds + (openDuration * 2).clamp(10, 120);
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

    FreezerViewData? f1 = _state.freezer1;
    if (f1 != null) {
      f1 = _tickFreezer(f1, now);
      if (f1.alertLevel.isCritical) {
        audioService.playDoorAlarm();
      }
    }

    FreezerViewData? f2 = _state.freezer2;
    if (f2 != null) {
      f2 = _tickFreezer(f2, now);
      if (f2.alertLevel.isCritical) {
        audioService.playDoorAlarm();
      }
    }

    _state = _state.copyWith(freezer1: f1, freezer2: f2);
    notifyListeners();
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
    if (freezerId == 'f1' && _state.freezer1 != null) {
      _state = _state.copyWith(
        freezer1: _state.freezer1!.copyWith(
          batchStatus: FreezerBatchStatus.cooling,
          clearFeedbackCountdown: true,
          lastFeedback: feedback,
        ),
      );
      notifyListeners();
    } else if (freezerId == 'f2' && _state.freezer2 != null) {
      _state = _state.copyWith(
        freezer2: _state.freezer2!.copyWith(
          batchStatus: FreezerBatchStatus.cooling,
          clearFeedbackCountdown: true,
          lastFeedback: feedback,
        ),
      );
      notifyListeners();
    }
  }

  void toggleSimulatorDoor(int freezerNum) {
    webSocketRepo.toggleSimulatorDoor(freezerNum);
  }

  void startFreezerBatch(String freezerId) {
    final now = DateTime.now();
    if (freezerId == 'f1' && _state.freezer1 != null) {
      final target = _state.freezer1!.targetCoolingMinutes;
      _state = _state.copyWith(
        freezer1: _state.freezer1!.copyWith(
          batchStatus: FreezerBatchStatus.cooling,
          remainingSeconds: target * 60,
          batchStartedAt: now,
          clearFeedbackCountdown: true,
        ),
      );
      notifyListeners();
    } else if (freezerId == 'f2' && _state.freezer2 != null) {
      final target = _state.freezer2!.targetCoolingMinutes;
      _state = _state.copyWith(
        freezer2: _state.freezer2!.copyWith(
          batchStatus: FreezerBatchStatus.cooling,
          remainingSeconds: target * 60,
          batchStartedAt: now,
          clearFeedbackCountdown: true,
        ),
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _telemSub?.cancel();
    if (_settingsListener != null) {
      settingsViewModel.removeListener(_settingsListener!);
    }
    _tickerTimer?.cancel();
    startFreezerBatchCommand.dispose();
    recordFeedbackCommand.dispose();
    toggleSimulatorDoorCommand.dispose();
    toggleSimulatorProbeCommand.dispose();
    super.dispose();
  }
}
