import 'dart:async';

import 'package:gm_fabrica_monitoramento/src/data/services/audio_service.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/data/freezer_repository.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_feedback_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_live_state.dart';
import 'package:gm_fabrica_monitoramento/src/utils/result.dart';
import 'package:signals/signals.dart';

final class FreezerMonitoringViewModel {
  final FreezerRepository _repository;
  final AudioService? _audioService;

  // --- Signals Reativos ---
  late final Signal<Map<String, FreezerLiveState>> freezers;
  late final Computed<List<FreezerLiveState>> activeFreezers;
  late final Computed<FreezerLiveState?> freezer1;
  late final Computed<FreezerLiveState?> freezer2;
  late final Computed<bool> hasDoorAlarm;

  StreamSubscription? _freezersSub;
  StreamSubscription? _readySub;
  StreamSubscription? _alarmSub;

  FreezerMonitoringViewModel(
    this._repository, {
    this._audioService,
  }) {
    _initSignals();
    _bindRepositoryStreams();
  }

  void _initSignals() {
    freezers = signal<Map<String, FreezerLiveState>>(
      _repository.currentFreezers,
    );

    activeFreezers = computed<List<FreezerLiveState>>(() {
      return freezers.value.values.toList();
    });

    freezer1 = computed<FreezerLiveState?>(() => freezers.value['f1']);
    freezer2 = computed<FreezerLiveState?>(() => freezers.value['f2']);

    hasDoorAlarm = computed<bool>(() {
      return freezers.value.values.any(
        (f) =>
            !f.isSensorOk ||
            (f.isDoorOpen &&
                f.accumulatedDoorOpenSeconds >=
                    _repository.doorCriticalSeconds),
      );
    });
  }

  void _bindRepositoryStreams() {
    _freezersSub = _repository.freezersStream.listen((data) {
      freezers.value = data;
    });

    _readySub = _repository.cycleReadyStream.listen((freezerId) {
      _audioService?.playFreezerReady();
    });

    _alarmSub = _repository.doorAlarmStream.listen((freezerId) {
      _audioService?.playDoorAlarm();
    });
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

  /// Reseta a calibração de um freezer para o valor padrão de fábrica
  Future<Result<Unit>> resetCalibration(
    String freezerId, {
    String? productId,
    int defaultSeconds = 1200,
  }) async {
    return _repository.resetCalibration(
      freezerId,
      productId: productId,
      defaultSeconds: defaultSeconds,
    );
  }

  void dispose() {
    _freezersSub?.cancel();
    _readySub?.cancel();
    _alarmSub?.cancel();
  }
}

