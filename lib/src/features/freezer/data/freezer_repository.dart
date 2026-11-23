import 'dart:async';
import 'dart:math';

import 'package:gm_fabrica_monitoramento/src/data/local/daos/freezer_dao.dart';
import 'package:gm_fabrica_monitoramento/src/data/remote/supabase_catalog_datasource.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/door_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/freezer_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/telemetry_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/freezer_model.dart';
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
  final CatalogRemoteDatasource? remoteDatasource;

  StreamSubscription? _wsSubscription;
  Timer? _tickerTimer;

  final Map<String, FreezerLiveState> _freezers = {};
  final Map<String, DateTime> _doorOpenSince = {};
  final Map<String, double> _tempWhenOpened = {};
  final Map<String, double> _baselineTempBeforeLoad = {};
  final Map<String, int> _executedSecondsInCycle = {};

  List<EquipmentModel> _availableEquipments = const [];
  bool _isSyncingEquipments = false;

  final _freezersStreamController =
      StreamController<Map<String, FreezerLiveState>>.broadcast();
  final _equipmentsStreamController =
      StreamController<List<EquipmentModel>>.broadcast();
  final _equipmentsLoadingController = StreamController<bool>.broadcast();
  final _cycleStartedController = StreamController<String>.broadcast();
  final _cycleReadyController = StreamController<String>.broadcast();
  final _doorToggleController =
      StreamController<({String freezerId, bool isOpen})>.broadcast();
  final _doorAlarmController = StreamController<String>.broadcast();

  static const int _maxHistoryPoints = 60;
  final int doorCriticalSeconds;
  final int inspectionThresholdSeconds;

  FreezerRepository({
    required this._freezerDao,
    required this._wsService,
    required this._productionRepo,
    this._engine = const FreezerAdaptiveEngine(),
    this.remoteDatasource,
    this.doorCriticalSeconds = 60,
    this.inspectionThresholdSeconds = 12,
  }) {
    _initDefaultFreezers();
    _startTicker();
    _listenWebsocket();
    _restoreActiveCyclesAndSync();
  }

  Stream<Map<String, FreezerLiveState>> get freezersStream =>
      _freezersStreamController.stream;
  Stream<List<EquipmentModel>> get availableEquipmentsStream =>
      _equipmentsStreamController.stream;
  Stream<bool> get isSyncingEquipmentsStream =>
      _equipmentsLoadingController.stream;
  Stream<String> get cycleStartedStream => _cycleStartedController.stream;
  Stream<String> get cycleReadyStream => _cycleReadyController.stream;
  Stream<({String freezerId, bool isOpen})> get doorToggleStream =>
      _doorToggleController.stream;
  Stream<String> get doorAlarmStream => _doorAlarmController.stream;

  Map<String, FreezerLiveState> get currentFreezers =>
      Map.unmodifiable(_freezers);
  List<EquipmentModel> get currentEquipments =>
      List.unmodifiable(_availableEquipments);
  bool get isSyncingEquipments => _isSyncingEquipments;

  FreezerLiveState? getFreezer(String freezerId) => _freezers[freezerId];

  void _initDefaultFreezers() {
    _freezers['f1'] = const FreezerLiveState(
      freezerId: 'f1',
      sensorIndex: 1,
      name: 'Sensor 1 (F1)',
      currentTemp: 4.0,
      isDoorOpen: false,
      isSensorOk: true,
      status: FreezerStatusEnum.idle,
      expectedDurationSeconds: 480,
      remainingSeconds: 480,
      calibratedBaseSeconds: 480,
    );

    _freezers['f2'] = const FreezerLiveState(
      freezerId: 'f2',
      sensorIndex: 2,
      name: 'Sensor 2 (F2)',
      currentTemp: -18.0,
      isDoorOpen: false,
      isSensorOk: true,
      status: FreezerStatusEnum.idle,
      expectedDurationSeconds: 480,
      remainingSeconds: 480,
      calibratedBaseSeconds: 480,
    );

    _emitState();
  }

  Future<void> _restoreActiveCyclesAndSync() async {
    // 0. Garante que f1 e f2 existam no SQLite local para satisfazer FKs
    final localFreezersRes = await _freezerDao.ensureSensorFreezersExist();
    if (localFreezersRes.isOk) {
      for (final row in localFreezersRes.valueOrThrow) {
        final current = _freezers[row.id];
        if (current != null) {
          _freezers[row.id] = current.copyWith(
            sensorIndex: row.idSensor,
            name: row.name,
            equipmentId: row.equipmentId,
            equipmentName: row.equipmentName,
            unloadMinSeconds: row.unloadMinSeconds,
            reloadMinSeconds: row.reloadMinSeconds,
            calibratedBaseSeconds: row.defaultCoolingSeconds,
            expectedDurationSeconds: row.defaultCoolingSeconds,
            remainingSeconds: row.defaultCoolingSeconds,
          );
        }
      }
    }

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

    // 3. Sincroniza equipamentos (`cost_centers`) e vínculos (`freezer_sensor_bindings`) do Supabase
    await refreshEquipmentsAndBindingsFromSupabase();
  }

  /// Busca equipamentos reais (`public.cost_centers` onde `type = 'equipamento'`)
  /// e os vínculos de sensores (`public.freezer_sensor_bindings`) no Supabase.
  Future<Result<List<EquipmentModel>>>
  refreshEquipmentsAndBindingsFromSupabase() => Result.catchInAsync(
    fn: () async {
      final remote = remoteDatasource;
      if (remote == null) return _availableEquipments;

      _isSyncingEquipments = true;
      if (!_equipmentsLoadingController.isClosed) {
        _equipmentsLoadingController.add(true);
      }

      try {
        final results = await Future.wait<dynamic>([
          remote.fetchEquipments(),
          remote.fetchFreezerSensorBindings(),
        ]);

        final equipments = results[0] as List<EquipmentModel>;
        final bindings = results[1] as List<FreezerSensorBindingModel>;

        _availableEquipments = equipments;
        if (!_equipmentsStreamController.isClosed) {
          _equipmentsStreamController.add(_availableEquipments);
        }

        // Mapa rápido de equipamentos por ID para resolver nome atualizado
        final eqById = {for (final e in equipments) e.id: e};

        if (bindings.isNotEmpty) {
          for (final b in bindings) {
            final linkedEq = b.costCenterId != null
                ? eqById[b.costCenterId!]
                : null;
            final resolvedBinding = FreezerSensorBindingModel(
              sensorKey: b.sensorKey,
              sensorIndex: b.sensorIndex,
              costCenterId: b.costCenterId,
              costCenterName: linkedEq?.name ?? b.costCenterName,
              customLabel: b.customLabel,
              targetTemperature: b.targetTemperature,
              criticalTemperature: b.criticalTemperature,
              defaultCoolingSeconds: b.defaultCoolingSeconds,
              unloadMinSeconds: b.unloadMinSeconds,
              reloadMinSeconds: b.reloadMinSeconds,
              inspectionThresholdSeconds: b.inspectionThresholdSeconds,
              maxDoorOpenSeconds: b.maxDoorOpenSeconds,
            );

            await _freezerDao.upsertFreezerBinding(resolvedBinding);
            _applyBindingToLiveState(resolvedBinding);
          }
        } else if (equipments.isNotEmpty) {
          // Auto-sugestão inteligente caso nenhum vínculo tenha sido salvo ainda
          // e existam equipamentos com nome contendo "Freezer"
          final freezerEquipments = equipments
              .where((e) => e.name.toLowerCase().contains('freezer'))
              .toList();
          for (var i = 0; i < min(2, freezerEquipments.length); i++) {
            final sensorKey = 'f${i + 1}';
            final current = _freezers[sensorKey];
            if (current != null && !current.hasLinkedEquipment) {
              await bindEquipmentToSensor(
                sensorKey: sensorKey,
                equipment: freezerEquipments[i],
              );
            }
          }
        }

        _emitState();
        return _availableEquipments;
      } finally {
        _isSyncingEquipments = false;
        if (!_equipmentsLoadingController.isClosed) {
          _equipmentsLoadingController.add(false);
        }
      }
    },
    tag: 'FreezerRepository.refreshEquipmentsAndBindingsFromSupabase',
  );

  void _applyBindingToLiveState(FreezerSensorBindingModel binding) {
    final current = _freezers[binding.sensorKey];
    if (current == null) return;

    final isIdle = current.status == FreezerStatusEnum.idle;
    final resolvedBase = current.isCalibrated
        ? current.calibratedBaseSeconds
        : binding.defaultCoolingSeconds;

    _freezers[binding.sensorKey] = current.copyWith(
      sensorIndex: binding.sensorIndex,
      name: binding.resolvedDisplayName,
      equipmentId: binding.costCenterId,
      clearEquipment: binding.costCenterId == null,
      equipmentName: binding.costCenterName,
      unloadMinSeconds: binding.unloadMinSeconds,
      reloadMinSeconds: binding.reloadMinSeconds,
      calibratedBaseSeconds: resolvedBase,
      expectedDurationSeconds: isIdle
          ? resolvedBase
          : current.expectedDurationSeconds,
      remainingSeconds: isIdle ? resolvedBase : current.remainingSeconds,
    );
  }

  /// Vincula (ou desvincula) um equipamento vindo do Supabase (`public.cost_centers`)
  /// a um sensor físico do ESP32 (`f1`, `f2`), persistindo no SQLite local e no Supabase.
  Future<Result<Unit>> bindEquipmentToSensor({
    required String sensorKey,
    required EquipmentModel? equipment,
  }) => Result.catchInAsync(
    fn: () async {
      final current = _freezers[sensorKey];
      if (current == null) return unit;

      final binding = FreezerSensorBindingModel(
        sensorKey: sensorKey,
        sensorIndex: current.sensorIndex,
        costCenterId: equipment?.id,
        costCenterName: equipment?.name,
        targetTemperature: sensorKey == 'f2' ? -18.0 : 4.0,
        criticalTemperature: sensorKey == 'f2' ? -5.0 : 8.0,
        defaultCoolingSeconds: current.calibratedBaseSeconds,
        unloadMinSeconds: current.unloadMinSeconds,
        reloadMinSeconds: current.reloadMinSeconds,
        inspectionThresholdSeconds: inspectionThresholdSeconds,
        maxDoorOpenSeconds: doorCriticalSeconds,
      );

      _applyBindingToLiveState(binding);
      _emitState();

      await _freezerDao.upsertFreezerBinding(binding);
      if (remoteDatasource != null) {
        await remoteDatasource!.upsertFreezerSensorBinding(binding);
      }

      return unit;
    },
    tag: 'FreezerRepository.bindEquipmentToSensor',
  );

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
    final prev =
        _freezers[raw.id] ??
        FreezerLiveState(
          freezerId: raw.id,
          sensorIndex: raw.id == 'f2' ? 2 : 1,
          name: raw.id == 'f1' ? 'Sensor 1 (F1)' : 'Sensor 2 (F2)',
          currentTemp: raw.temp,
          isDoorOpen: raw.isDoorOpen,
          isSensorOk: raw.isSensorOk,
          status: FreezerStatusEnum.idle,
          expectedDurationSeconds: 480,
          remainingSeconds: 480,
        );

    final doorChanged = prev.isDoorOpen != raw.isDoorOpen;

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

    if (!_doorToggleController.isClosed) {
      _doorToggleController.add((freezerId: id, isOpen: isNowOpen));
    }

    if (isNowOpen) {
      _doorOpenSince[id] = now;
      _tempWhenOpened[id] = temp;

      if (state.status == FreezerStatusEnum.idle) {
        _baselineTempBeforeLoad[id] = temp;
      }

      if (state.status == FreezerStatusEnum.cooling) {
        return state.copyWith(
          isDoorOpen: true,
          currentDoorOpenSeconds: 0,
          status: FreezerStatusEnum.doorOpen,
          baselineTemp: state.baselineTemp ?? temp,
          lastDoorOpenTemp: temp,
          peakTemp: max(state.peakTemp ?? temp, temp),
          doorTransitions: transitions,
        );
      }

      return state.copyWith(
        isDoorOpen: true,
        currentDoorOpenSeconds: 0,
        baselineTemp: state.baselineTemp ?? temp,
        lastDoorOpenTemp: temp,
        peakTemp: temp,
        doorTransitions: transitions,
      );
    } else {
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

        if (!isInspection) {
          final baseline = _baselineTempBeforeLoad[id] ?? openedTemp;
          final peakTemp = recordedPeak;

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

      // CASO 2: Estava em RESFRIAMENTO (COOLING ou DOOR_OPEN)
      if (state.status == FreezerStatusEnum.cooling ||
          state.status == FreezerStatusEnum.doorOpen) {
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

      // CASO 3: Estava PRONTO (READY)
      if (state.status == FreezerStatusEnum.ready) {
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

        if (s.isDoorOpen) {
          final openSec = _doorOpenSince[id] != null
              ? max(1, now.difference(_doorOpenSince[id]!).inSeconds)
              : s.currentDoorOpenSeconds + 1;
          s = s.copyWith(currentDoorOpenSeconds: openSec);
          _freezers[id] = s;
          changed = true;
          if (openSec >= doorCriticalSeconds &&
              !_doorAlarmController.isClosed) {
            _doorAlarmController.add(id);
          }
        }

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
          final cd = s.feedbackCountdownSeconds ?? 30;
          if (cd <= 1) {
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

    if (!_cycleStartedController.isClosed) {
      _cycleStartedController.add(freezerId);
    }

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
  /// e usando o tempo real corrido para calibrar o próximo ciclo.
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

    if (feedback == FreezerFeedbackEnum.soft) {
      final extensionSec = _engine.immediateExtensionSeconds(
        feedback: feedback,
      );

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

  /// Cancela o ciclo em andamento
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

  /// Reinicia manualmente a contagem do ciclo
  Future<void> restartCycle(String freezerId) async {
    final current = _freezers[freezerId];
    if (current == null) return;

    await _startAdaptiveCycleInternal(
      freezerId: freezerId,
      baselineTemp: current.effectiveBaselineTemp,
      peakTemp: current.currentTemp,
    );
  }

  /// Atualiza os parâmetros de tempo de porta do sensor, tempo alvo base e opcionalmente o equipamento vinculado
  Future<void> updateDoorTimingConfig(
    String freezerId, {
    required int unloadMinSeconds,
    required int reloadMinSeconds,
    int? targetDurationSeconds,
    EquipmentModel? linkedEquipment,
    bool updateEquipmentBinding = false,
  }) async {
    final current = _freezers[freezerId];
    if (current == null) return;

    final safeUnload = unloadMinSeconds.clamp(10, 300);
    final safeReload = max(safeUnload + 10, reloadMinSeconds.clamp(20, 600));
    final newBase = targetDurationSeconds != null
        ? targetDurationSeconds.clamp(60, 7200)
        : current.calibratedBaseSeconds;

    final isIdle = current.status == FreezerStatusEnum.idle;
    final elapsed =
        _executedSecondsInCycle[freezerId] ?? current.elapsedSeconds;
    final newExpected = isIdle
        ? newBase
        : newBase + current.accumulatedPenaltySeconds;
    final newRemaining = isIdle ? newBase : max(0, newExpected - elapsed);

    FreezerStatusEnum updatedStatus = current.status;
    if (current.status == FreezerStatusEnum.cooling && newRemaining == 0) {
      updatedStatus = FreezerStatusEnum.ready;
    } else if (current.status == FreezerStatusEnum.ready && newRemaining > 0) {
      updatedStatus = FreezerStatusEnum.cooling;
    }

    final resolvedEquipmentId = updateEquipmentBinding
        ? linkedEquipment?.id
        : current.equipmentId;
    final resolvedEquipmentName = updateEquipmentBinding
        ? linkedEquipment?.name
        : current.equipmentName;
    final resolvedName =
        (resolvedEquipmentName != null &&
            resolvedEquipmentName.trim().isNotEmpty)
        ? resolvedEquipmentName
        : 'Sensor ${current.sensorIndex} (${freezerId.toUpperCase()})';

    _freezers[freezerId] = current.copyWith(
      name: resolvedName,
      equipmentId: resolvedEquipmentId,
      clearEquipment: updateEquipmentBinding && linkedEquipment == null,
      equipmentName: resolvedEquipmentName,
      status: updatedStatus,
      unloadMinSeconds: safeUnload,
      reloadMinSeconds: safeReload,
      calibratedBaseSeconds: newBase,
      expectedDurationSeconds: newExpected,
      remainingSeconds: newRemaining,
    );

    _emitState();

    // Persiste no SQLite (calibração base + vínculo do freezer) e SharedPreferences
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

    final binding = FreezerSensorBindingModel(
      sensorKey: freezerId,
      sensorIndex: current.sensorIndex,
      costCenterId: resolvedEquipmentId,
      costCenterName: resolvedEquipmentName,
      targetTemperature: freezerId == 'f2' ? -18.0 : 4.0,
      criticalTemperature: freezerId == 'f2' ? -5.0 : 8.0,
      defaultCoolingSeconds: newBase,
      unloadMinSeconds: safeUnload,
      reloadMinSeconds: safeReload,
      inspectionThresholdSeconds: inspectionThresholdSeconds,
      maxDoorOpenSeconds: doorCriticalSeconds,
    );
    await _freezerDao.upsertFreezerBinding(binding);
    if (remoteDatasource != null) {
      try {
        await remoteDatasource!.upsertFreezerSensorBinding(binding);
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('freezer_${freezerId}_unload_sec', safeUnload);
      await prefs.setInt('freezer_${freezerId}_reload_sec', safeReload);
      await prefs.setInt('freezer_${freezerId}_target_sec', newBase);
    } catch (_) {}
  }

  /// Reseta calibração para valores padrão (8 minutos = 480s)
  Future<Result<Unit>> resetCalibration(
    String freezerId, {
    String? productId,
    int defaultSeconds = 480,
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
          expectedDurationSeconds:
              current.status == FreezerStatusEnum.idle
                  ? defaultSeconds
                  : current.expectedDurationSeconds,
          remainingSeconds:
              current.status == FreezerStatusEnum.idle
                  ? defaultSeconds
                  : current.remainingSeconds,
          isCalibrated: false,
        );
        _emitState();
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('freezer_${freezerId}_target_sec');
      } catch (_) {}
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
    _equipmentsStreamController.close();
    _equipmentsLoadingController.close();
    _cycleStartedController.close();
    _cycleReadyController.close();
    _doorToggleController.close();
    _doorAlarmController.close();
  }
}

void unawaited(Future<void> future) {}
