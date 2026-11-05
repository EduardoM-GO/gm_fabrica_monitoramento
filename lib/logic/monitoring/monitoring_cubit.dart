import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/freezer_view_data.dart';
import '../../data/models/telemetry_model.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/mock_telemetry_generator.dart';
import '../../data/services/websocket_service.dart';
import '../settings/settings_cubit.dart';
import 'monitoring_state.dart';

class MonitoringCubit extends Cubit<MonitoringState> {
  final SettingsCubit settingsCubit;
  final AudioService audioService;

  late IWebSocketService _webSocketService;
  MockWebSocketService? _mockService;

  StreamSubscription? _settingsSub;
  StreamSubscription? _msgSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _errorSub;
  Timer? _tickerTimer;
  Timer? _hitAnimationTimer;

  final List<DateTime> _recentHitTimestamps = [];
  static const int _maxHistoryPoints = 60;

  MonitoringCubit({
    required this.settingsCubit,
    required this.audioService,
    IWebSocketService? webSocketService,
  }) : super(MonitoringState.initial(
          defaultBoxCapacity: settingsCubit.state.defaultBoxCapacity,
        )) {
    _init(webSocketService);
  }

  void _init(IWebSocketService? customWs) {
    _setupService(customWs);

    // React to settings changes (URL, thresholds, audio toggles, mock toggle)
    _settingsSub = settingsCubit.stream.listen((settings) {
      audioService.eggSoundEnabled = settings.eggSoundEnabled;
      audioService.alarmSoundEnabled = settings.alarmSoundEnabled;

      if (settings.isMockEnabled && _mockService == null) {
        _switchToMock();
      } else if (!settings.isMockEnabled && _mockService != null) {
        _switchToReal(settings.wsUrl);
      }
    });

    // Start 1-second UI ticker to refresh durations and rate calculations
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _setupService(IWebSocketService? customWs) {
    if (customWs != null) {
      _webSocketService = customWs;
    } else if (settingsCubit.state.isMockEnabled) {
      _mockService = MockWebSocketService();
      _webSocketService = _mockService!;
    } else {
      _mockService = null;
      _webSocketService = WebSocketServiceImpl();
    }

    _subscribeToService();
    _webSocketService.connect(settingsCubit.state.wsUrl);
  }

  void _switchToMock() {
    _cleanupService();
    _mockService = MockWebSocketService();
    _webSocketService = _mockService!;
    _subscribeToService();
    _webSocketService.connect('mock://internal');
  }

  void _switchToReal(String url) {
    _cleanupService();
    _mockService = null;
    _webSocketService = WebSocketServiceImpl();
    _subscribeToService();
    _webSocketService.connect(url);
  }

  void _subscribeToService() {
    _statusSub?.cancel();
    _statusSub = _webSocketService.statusStream.listen((status) {
      emit(state.copyWith(connectionStatus: status));
    });

    _errorSub?.cancel();
    _errorSub = _webSocketService.errorStream.listen((err) {
      emit(state.copyWith(
        connectionErrorMessage: err,
        clearError: err == null,
      ));
    });

    _msgSub?.cancel();
    _msgSub = _webSocketService.messageStream.listen(_handleIncomingJson);
  }

  void _cleanupService() {
    _msgSub?.cancel();
    _statusSub?.cancel();
    _errorSub?.cancel();
    _webSocketService.disconnect();
  }

  void _handleIncomingJson(Map<String, dynamic> json) {
    try {
      final frame = IncomingFrame.fromJson(json);
      if (frame is TelemetryFrame) {
        _processTelemetry(frame);
      } else if (frame is HitFrame) {
        _processHit(frame);
      }
    } catch (_) {
      // Ignored malformed frames
    }
  }

  void _processTelemetry(TelemetryFrame frame) {
    final now = DateTime.now();

    final f1 = frame.freezer1 != null
        ? _computeFreezerState(
            previous: state.freezer1,
            raw: frame.freezer1!,
            defaultId: 'f1',
            defaultName: 'Freezer 1 (Câmara)',
            defaultTargetMinutes: settingsCubit.state.freezer1BaseMinutes,
            now: now,
          )
        : state.freezer1;

    final f2 = frame.freezer2 != null
        ? _computeFreezerState(
            previous: state.freezer2,
            raw: frame.freezer2!,
            defaultId: 'f2',
            defaultName: 'Freezer 2 (Congelamento)',
            defaultTargetMinutes: settingsCubit.state.freezer2BaseMinutes,
            now: now,
          )
        : state.freezer2;

    // Play alarm if any active freezer is critical
    if ((f1 != null && f1.alertLevel.isCritical) ||
        (f2 != null && f2.alertLevel.isCritical)) {
      audioService.playDoorAlarm();
    }

    final newBatchCount = (frame.eggCount - state.batchOffset).clamp(0, 9999999);

    emit(state.copyWith(
      uptimeMs: frame.uptimeMs,
      rawEggCount: frame.eggCount,
      batchEggCount: newBatchCount,
      freezer1: f1,
      freezer2: f2,
      lastTelemTime: now,
    ));
  }

  FreezerViewData _computeFreezerState({
    required FreezerViewData? previous,
    required FreezerRawData raw,
    required String defaultId,
    required String defaultName,
    required int defaultTargetMinutes,
    required DateTime now,
  }) {
    final prev = previous ??
        FreezerViewData(
          id: defaultId,
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

    // Determine alert level based on configurable settings
    DoorAlertLevel alertLevel = DoorAlertLevel.normal;
    if (raw.isDoorOpen && doorStateSince != null) {
      final openSeconds = now.difference(doorStateSince).inSeconds;
      if (openSeconds >= settingsCubit.state.doorCriticalSeconds) {
        alertLevel = DoorAlertLevel.critical;
      } else if (openSeconds >= settingsCubit.state.doorWarningSeconds) {
        alertLevel = DoorAlertLevel.warning;
      }
    }

    // Append to temperature history
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
        // Door just opened
        batchStatus = FreezerBatchStatus.doorOpen;
      } else {
        // Door just closed: evaluate how long it was open
        final openDuration = prev.doorStateSince != null
            ? now.difference(prev.doorStateSince!).inSeconds
            : 0;

        if (openDuration >= settingsCubit.state.doorInspectionThresholdSeconds) {
          // Prolonged opening: batch completed/unloaded, new batch loaded
          batchStatus = FreezerBatchStatus.feedbackPending;
          feedbackCountdownSeconds = 30;
          batchStartedAt = now;
          remainingSeconds = prev.targetCoolingMinutes * 60;
        } else {
          // Quick peek: keep batch running, compensate for thermal loss
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

  void _processHit(HitFrame frame) {
    final now = DateTime.now();

    // Trigger audio & haptic feedback immediately
    audioService.playEggHit();

    // Slide-window calculation for eggs/minute
    _recentHitTimestamps.add(now);
    _cleanupOldHits(now);

    final delta = (frame.eggCount > state.rawEggCount)
        ? (frame.eggCount - state.rawEggCount)
        : 1;

    _registerEggCountDelta(delta, rawCount: frame.eggCount, now: now);
  }

  void _registerEggCountDelta(int delta, {int? rawCount, DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    final newRawCount = rawCount ?? (state.rawEggCount + delta);
    final newBatchCount = (newRawCount - state.batchOffset).clamp(0, 9999999);
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

    emit(state.copyWith(
      rawEggCount: newRawCount,
      batchEggCount: newBatchCount,
      dailyTotalEggs: newDailyTotal,
      currentBoxCount: newBoxCount,
      completedBoxesCount: state.completedBoxesCount + completedIncrement,
      isHitAnimating: true,
      isBoxJustCompleted: justCompleted,
      lastHitTime: timestamp,
      eggsPerMinute: _calculateEggsPerMinute(timestamp),
    ));
  }

  /// Manual +1 egg increment (with sound and box calculation)
  void incrementEggManual() {
    audioService.playEggHit();
    final now = DateTime.now();
    _recentHitTimestamps.add(now);
    _cleanupOldHits(now);
    _registerEggCountDelta(1, now: now);
  }

  /// Manual -1 egg decrement (undo mistrigger)
  void decrementEggManual() {
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

  /// Sets box capacity (e.g. 40 or 50) and updates default setting
  void setBoxCapacity(int capacity) {
    if (capacity <= 0 || capacity == state.boxCapacity) return;
    emit(state.copyWith(boxCapacity: capacity));
    settingsCubit.updateDefaultBoxCapacity(capacity);
  }

  /// Resets current box count to 0 without affecting completed boxes or daily total
  void resetCurrentBox() {
    emit(state.copyWith(currentBoxCount: 0));
  }

  /// Resets entire day counts
  void resetDailyTotal() {
    emit(state.copyWith(
      dailyTotalEggs: 0,
      completedBoxesCount: 0,
      currentBoxCount: 0,
      batchOffset: state.rawEggCount,
      batchEggCount: 0,
    ));
  }

  /// Records post-pickup quality feedback and returns freezer to cooling
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

  /// Manually starts/restarts a cooling batch for a freezer
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

  void _onTick() {
    final now = DateTime.now();
    _cleanupOldHits(now);

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
      eggsPerMinute: _calculateEggsPerMinute(now),
    ));
  }

  FreezerViewData _tickFreezer(FreezerViewData freezer, DateTime now) {
    final alert = _recheckAlert(freezer, now);
    var updated = freezer.copyWith(alertLevel: alert);

    if (freezer.batchStatus == FreezerBatchStatus.cooling) {
      final rem = (freezer.remainingSeconds - 1).clamp(0, 99999);
      if (rem == 0) {
        audioService.playFreezerReady();
        updated = updated.copyWith(
          remainingSeconds: 0,
          batchStatus: FreezerBatchStatus.ready,
        );
      } else {
        updated = updated.copyWith(remainingSeconds: rem);
      }
    } else if (freezer.batchStatus == FreezerBatchStatus.feedbackPending) {
      if (freezer.feedbackCountdownSeconds != null) {
        final cd = freezer.feedbackCountdownSeconds! - 1;
        if (cd <= 0) {
          // Auto-dismiss: record default "Tudo OK"
          updated = updated.copyWith(
            clearFeedbackCountdown: true,
            batchStatus: FreezerBatchStatus.cooling,
            lastFeedback: 'No ponto (Automático)',
          );
        } else {
          updated = updated.copyWith(feedbackCountdownSeconds: cd);
        }
      }
    }

    return updated;
  }

  DoorAlertLevel _recheckAlert(FreezerViewData freezer, DateTime now) {
    if (!freezer.isDoorOpen || freezer.doorStateSince == null) {
      return DoorAlertLevel.normal;
    }
    final seconds = now.difference(freezer.doorStateSince!).inSeconds;
    if (seconds >= settingsCubit.state.doorCriticalSeconds) {
      return DoorAlertLevel.critical;
    } else if (seconds >= settingsCubit.state.doorWarningSeconds) {
      return DoorAlertLevel.warning;
    }
    return DoorAlertLevel.normal;
  }

  void _cleanupOldHits(DateTime now) {
    _recentHitTimestamps.removeWhere(
      (time) => now.difference(time).inSeconds > 60,
    );
  }

  double _calculateEggsPerMinute(DateTime now) {
    if (_recentHitTimestamps.isEmpty) return 0.0;
    // In a 60-second window, count of timestamps equals hits/minute
    return _recentHitTimestamps.length.toDouble();
  }

  /// Resets the current production batch counter back to zero
  void resetBatch() {
    emit(state.copyWith(
      batchOffset: state.rawEggCount,
      batchEggCount: 0,
    ));
  }

  /// Reconnects with a new URL
  void reconnectWithUrl(String url) {
    settingsCubit.updateWsUrl(url);
    if (!settingsCubit.state.isMockEnabled) {
      _switchToReal(url);
    }
  }

  // Simulator helper methods (for interactive demo / testing)
  void simulateEggHit() {
    if (_mockService != null) {
      _mockService!.triggerEggHit();
    } else {
      _processHit(HitFrame(eggCount: state.rawEggCount + 1));
    }
  }

  void toggleSimulatorDoor(int freezerNum) {
    _mockService?.toggleDoor(freezerNum);
  }

  void toggleSimulatorProbe(int freezerNum) {
    _mockService?.toggleProbe(freezerNum);
  }

  @override
  Future<void> close() {
    _tickerTimer?.cancel();
    _hitAnimationTimer?.cancel();
    _settingsSub?.cancel();
    _errorSub?.cancel();
    _cleanupService();
    _webSocketService.dispose();
    return super.close();
  }
}

