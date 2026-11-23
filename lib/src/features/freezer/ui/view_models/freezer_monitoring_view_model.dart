import 'dart:async';

import 'package:gm_fabrica_monitoramento/src/data/services/audio_service.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/freezer_model.dart';
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
  late final Signal<List<EquipmentModel>> availableEquipments;
  late final Signal<bool> isSyncingEquipments;
  late final Computed<List<FreezerLiveState>> activeFreezers;
  late final Computed<FreezerLiveState?> freezer1;
  late final Computed<FreezerLiveState?> freezer2;
  late final Computed<bool> hasDoorAlarm;

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

  void _initSignals() {
    freezers = signal<Map<String, FreezerLiveState>>(
      _repository.currentFreezers,
    );
    availableEquipments = signal<List<EquipmentModel>>(
      _repository.currentEquipments,
    );
    isSyncingEquipments = signal<bool>(_repository.isSyncingEquipments);

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
                (f.currentDoorOpenSeconds >= _repository.doorCriticalSeconds ||
                    f.accumulatedDoorOpenSeconds >=
                        _repository.doorCriticalSeconds)),
      );
    });
  }

  void _bindRepositoryStreams() {
    _freezersSub = _repository.freezersStream.listen((data) {
      freezers.value = data;
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
    _equipmentsSub?.cancel();
    _equipmentsLoadingSub?.cancel();
    _startedSub?.cancel();
    _readySub?.cancel();
    _doorToggleSub?.cancel();
    _alarmSub?.cancel();
  }
}
