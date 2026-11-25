import 'dart:async';
import 'dart:math';

import 'package:gm_fabrica_monitoramento/src/data/local/daos/freezer_dao.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/trigger_freezer_enum.dart';
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
  late final Future<void> _readyFuture;

  final Map<String, FreezerLiveState> _freezers = {};
  final Map<String, DateTime> _cycleStartedAt = {};
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
  final _defrostToggleController =
      StreamController<({String freezerId, bool isDefrosting})>.broadcast();

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
    _readyFuture = _restoreActiveCyclesAndSync();
  }

  /// Aguarda a restauração dos ciclos ativos e configurações locais no SQLite/SharedPreferences
  Future<void> get ready => _readyFuture;

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
  Stream<({String freezerId, bool isDefrosting})> get defrostToggleStream =>
      _defrostToggleController.stream;

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

      // 2. Restaura ciclo ativo se houver (SQLite + fallback SharedPreferences)
      final cycleResult = await _freezerDao.getActiveCoolingCycle(id);
      final savedLastOpenTemp = prefs?.getDouble('freezer_${id}_last_open_temp');
      final savedLastCloseTemp = prefs?.getDouble('freezer_${id}_last_close_temp');
      final savedLastCloseMs = prefs?.getInt('freezer_${id}_last_close_ms');
      final savedLastTemp = prefs?.getDouble('freezer_${id}_last_temp');
      final savedLastCloseAt = savedLastCloseMs != null
          ? DateTime.fromMillisecondsSinceEpoch(savedLastCloseMs)
          : null;

      if (cycleResult.isOk && cycleResult.valueOrThrow != null) {
        final cycle = cycleResult.valueOrThrow!;
        final elapsed = max(
          0,
          DateTime.now().difference(cycle.startedAt).inSeconds,
        );
        final remaining = max(0, cycle.expectedDurationSeconds - elapsed);
        final afterCal = _freezers[id];
        if (afterCal != null) {
          _cycleStartedAt[id] = cycle.startedAt;
          _executedSecondsInCycle[id] = elapsed;
          _freezers[id] = afterCal.copyWith(
            currentTemp: savedLastTemp ?? afterCal.currentTemp,
            status: remaining == 0
                ? FreezerStatusEnum.ready
                : FreezerStatusEnum.cooling,
            expectedDurationSeconds: cycle.expectedDurationSeconds,
            remainingSeconds: remaining,
            elapsedSeconds: elapsed,
            activeCycleId: cycle.id,
            baselineTemp: cycle.baselineTemp,
            peakTemp: cycle.initialPeakTemp,
            lastDoorOpenTemp: savedLastOpenTemp,
            lastDoorCloseTemp: savedLastCloseTemp,
            lastDoorCloseAt: savedLastCloseAt,
            accumulatedDoorOpenSeconds: cycle.accumulatedDoorOpenSeconds,
            accumulatedPenaltySeconds: cycle.accumulatedPenaltySeconds,
            doorOpenCount: cycle.doorOpenCount,
            accumulatedDefrostSeconds: cycle.accumulatedDefrostSeconds,
          );
        }
      } else {
        // Fallback: caso o ciclo tenha sido salvo nas SharedPreferences ou apenas o contexto térmico
        final savedCycleStartMs = prefs?.getInt('freezer_${id}_active_start_ms');
        final savedCycleExpected = prefs?.getInt(
          'freezer_${id}_active_expected_sec',
        );
        final afterCal = _freezers[id];
        if (afterCal != null) {
          if (savedCycleStartMs != null && savedCycleExpected != null) {
            final startedAt = DateTime.fromMillisecondsSinceEpoch(
              savedCycleStartMs,
            );
            final elapsed = max(0, DateTime.now().difference(startedAt).inSeconds);
            final remaining = max(0, savedCycleExpected - elapsed);
            _cycleStartedAt[id] = startedAt;
            _executedSecondsInCycle[id] = elapsed;
            _freezers[id] = afterCal.copyWith(
              currentTemp: savedLastTemp ?? afterCal.currentTemp,
              status: remaining == 0
                  ? FreezerStatusEnum.ready
                  : FreezerStatusEnum.cooling,
              expectedDurationSeconds: savedCycleExpected,
              remainingSeconds: remaining,
              elapsedSeconds: elapsed,
              baselineTemp: prefs?.getDouble('freezer_${id}_active_base_temp'),
              peakTemp: prefs?.getDouble('freezer_${id}_active_peak_temp'),
              lastDoorOpenTemp: savedLastOpenTemp,
              lastDoorCloseTemp: savedLastCloseTemp,
              lastDoorCloseAt: savedLastCloseAt,
            );
          } else if (savedLastTemp != null || savedLastCloseAt != null) {
            _freezers[id] = afterCal.copyWith(
              currentTemp: savedLastTemp ?? afterCal.currentTemp,
              lastDoorOpenTemp: savedLastOpenTemp,
              lastDoorCloseTemp: savedLastCloseTemp,
              lastDoorCloseAt: savedLastCloseAt,
            );
          }
        }
      }

      // 2.5 Restaura estado de degelo (Frost Free desligado) caso o app tenha reiniciado durante o degelo
      final savedDefrosting = prefs?.getBool('freezer_${id}_is_defrosting') ?? false;
      final afterRestore = _freezers[id];
      if (savedDefrosting && afterRestore != null) {
        final savedDefrostStartMs = prefs?.getInt('freezer_${id}_defrost_start_ms');
        final savedDefrostStartTemp = prefs?.getDouble('freezer_${id}_defrost_start_temp');
        final savedDefrostPeakTemp = prefs?.getDouble('freezer_${id}_defrost_peak_temp');
        final defrostStartedAt = savedDefrostStartMs != null
            ? DateTime.fromMillisecondsSinceEpoch(savedDefrostStartMs)
            : DateTime.now();
        final currentDefrostSec = max(
          0,
          DateTime.now().difference(defrostStartedAt).inSeconds,
        );
        _freezers[id] = afterRestore.copyWith(
          isDefrosting: true,
          defrostStartedAt: defrostStartedAt,
          defrostStartTemp: savedDefrostStartTemp ?? afterRestore.currentTemp,
          defrostPeakTemp: savedDefrostPeakTemp ?? afterRestore.currentTemp,
          currentDefrostSeconds: currentDefrostSec,
        );
      }
    }
    _emitState();

    // 3. Sincroniza equipamentos (`cost_centers`) e vínculos (`freezer_sensor_bindings`) do Supabase em background
    unawaited(refreshEquipmentsAndBindingsFromSupabase());
  }

  /// Recalcula imediatamente o tempo decorrido dos ciclos ativos ao retomar o app do background
  Future<void> onAppLifecycleStateChanged({required bool isResumed}) async {
    if (!isResumed) return;

    final now = DateTime.now();
    bool changed = false;
    for (final entry in _freezers.entries) {
      final id = entry.key;
      final s = entry.value;
      final startedAt = _cycleStartedAt[id];

      if (s.isDefrosting) {
        final defrostSec = s.defrostStartedAt != null
            ? max(1, now.difference(s.defrostStartedAt!).inSeconds)
            : s.currentDefrostSeconds;
        final defrostDelta = max(0, defrostSec - s.currentDefrostSeconds);
        final hasActiveCycle =
            s.status == FreezerStatusEnum.cooling ||
            s.status == FreezerStatusEnum.doorOpen;
        _freezers[id] = s.copyWith(
          currentDefrostSeconds: defrostSec,
          accumulatedDefrostSeconds: hasActiveCycle
              ? s.accumulatedDefrostSeconds + defrostDelta
              : s.accumulatedDefrostSeconds,
          expectedDurationSeconds: hasActiveCycle
              ? s.expectedDurationSeconds + defrostDelta
              : s.expectedDurationSeconds,
        );
        changed = true;
        continue;
      }

      if (startedAt != null &&
          (s.status == FreezerStatusEnum.cooling ||
              s.status == FreezerStatusEnum.doorOpen ||
              s.status == FreezerStatusEnum.ready)) {
        final totalWall = max(0, now.difference(startedAt).inSeconds);
        final elapsed = max(0, totalWall - s.accumulatedDefrostSeconds);
        final rem = max(0, s.expectedDurationSeconds - elapsed);
        _executedSecondsInCycle[id] = elapsed;
        _freezers[id] = s.copyWith(
          elapsedSeconds: elapsed,
          remainingSeconds: rem,
          status: (s.status == FreezerStatusEnum.cooling && rem == 0)
              ? FreezerStatusEnum.ready
              : s.status,
        );
        changed = true;
      }
    }
    if (changed) {
      _emitState();
    }
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
      defrostPeakTemp: prev.isDefrosting
          ? max(prev.defrostPeakTemp ?? raw.temp, raw.temp)
          : prev.defrostPeakTemp,
      isDoorOpen: raw.isDoorOpen,
      isSensorOk: raw.isSensorOk,
      temperatureHistory: history,
    );

    if (doorChanged) {
      updated = _handleDoorTransition(updated, raw.isDoorOpen, raw.temp, now);
    }

    updated = _evaluateDefrostState(updated, now);

    _freezers[raw.id] = updated;
    unawaited(_persistThermalSnapshot(updated));
    _emitState();
  }

  /// Avalia se o freezer entrou ou saiu do ciclo de degelo (Frost Free desligado)
  /// com base na curva térmica ao vivo e nas regras de inércia pós-porta.
  FreezerLiveState _evaluateDefrostState(FreezerLiveState state, DateTime now) {
    if (!state.isSensorOk) return state;

    if (!state.isDefrosting) {
      final shouldEnterDefrost = _engine.detectDefrostStart(
        currentTemp: state.currentTemp,
        isDoorOpen: state.isDoorOpen,
        now: now,
        lastDoorCloseAt: state.lastDoorCloseAt,
        history: state.temperatureHistory,
      );
      if (shouldEnterDefrost) {
        return _enterDefrostInternal(state, now);
      }
      return state;
    } else {
      final hasActiveCycle =
          state.status == FreezerStatusEnum.cooling ||
          state.status == FreezerStatusEnum.doorOpen;
      final peak = max(
        state.currentTemp,
        state.defrostPeakTemp ?? state.currentTemp,
      );
      final shouldExitDefrost = _engine.detectDefrostEnd(
        currentTemp: state.currentTemp,
        defrostPeakTemp: peak,
        hasActiveCycle: hasActiveCycle,
      );
      if (shouldExitDefrost) {
        return _exitDefrostInternal(state, now);
      }
      return state;
    }
  }

  FreezerLiveState _enterDefrostInternal(
    FreezerLiveState state,
    DateTime now,
  ) {
    if (state.isDefrosting) return state;

    // Descobre a temperatura de início do degelo na janela recente (ou usa a temperatura atual)
    double startTemp = state.currentTemp;
    final cutoff = now.subtract(const Duration(seconds: 180));
    for (final pt in state.temperatureHistory) {
      if (!pt.timestamp.isBefore(cutoff) && pt.temperature < startTemp) {
        startTemp = pt.temperature;
      }
    }

    final updated = state.copyWith(
      isDefrosting: true,
      defrostStartedAt: now,
      defrostStartTemp: startTemp,
      defrostPeakTemp: state.currentTemp,
      currentDefrostSeconds: 0,
    );

    if (!_defrostToggleController.isClosed) {
      _defrostToggleController.add((
        freezerId: state.freezerId,
        isDefrosting: true,
      ));
    }

    unawaited(_persistDefrostPrefs(updated));
    unawaited(
      _freezerDao.logRawFreezerEvent(
        freezerId: state.freezerId,
        batchId: _productionRepo.currentActiveBatch?.id,
        temperature: state.currentTemp,
        isDoorOpen: state.isDoorOpen,
        triggerReason: TriggerFreezerEnum.defrostStarted,
        recordedAt: now,
      ),
    );

    return updated;
  }

  FreezerLiveState _exitDefrostInternal(
    FreezerLiveState state,
    DateTime now,
  ) {
    if (!state.isDefrosting) return state;

    final hasActiveCycle =
        state.status == FreezerStatusEnum.cooling ||
        state.status == FreezerStatusEnum.doorOpen;

    int recoveryBonusSec = 0;
    if (hasActiveCycle) {
      final startTemp = state.defrostStartTemp ?? state.currentTemp;
      final peakTemp = max(
        state.currentTemp,
        state.defrostPeakTemp ?? state.currentTemp,
      );
      recoveryBonusSec = _engine.calculateDefrostRecoverySeconds(
        defrostStartTemp: startTemp,
        defrostPeakTemp: peakTemp,
      );
    }

    final newExpected = state.expectedDurationSeconds + recoveryBonusSec;
    final newRemaining = state.remainingSeconds + recoveryBonusSec;
    final newAccPenalty = state.accumulatedPenaltySeconds + recoveryBonusSec;

    if (state.activeCycleId != null) {
      unawaited(
        _freezerDao.updateCoolingCycleMetrics(
          cycleId: state.activeCycleId!,
          expectedDurationSeconds: newExpected,
          accumulatedDoorOpenSeconds: state.accumulatedDoorOpenSeconds,
          accumulatedPenaltySeconds: newAccPenalty,
          doorOpenCount: state.doorOpenCount,
          accumulatedDefrostSeconds: state.accumulatedDefrostSeconds,
        ),
      );
    }

    final updated = state.copyWith(
      clearDefrostState: true,
      expectedDurationSeconds: newExpected,
      remainingSeconds: newRemaining,
      accumulatedPenaltySeconds: newAccPenalty,
    );

    if (!_defrostToggleController.isClosed) {
      _defrostToggleController.add((
        freezerId: state.freezerId,
        isDefrosting: false,
      ));
    }

    unawaited(_clearDefrostPrefs(state.freezerId));
    if (hasActiveCycle) {
      unawaited(_persistActiveCyclePrefs(updated));
    }
    unawaited(
      _freezerDao.logRawFreezerEvent(
        freezerId: state.freezerId,
        batchId: _productionRepo.currentActiveBatch?.id,
        temperature: state.currentTemp,
        isDoorOpen: state.isDoorOpen,
        triggerReason: TriggerFreezerEnum.defrostEnded,
        recordedAt: now,
      ),
    );

    return updated;
  }

  /// Permite ao operador ativar ou encerrar manualmente o modo Degelo (Motor Off) pelo menu de toque longo
  Future<void> setManualDefrostMode(
    String freezerId, {
    required bool isDefrosting,
  }) async {
    final current = _freezers[freezerId];
    if (current == null || current.isDefrosting == isDefrosting) return;

    final now = DateTime.now();
    final updated = isDefrosting
        ? _enterDefrostInternal(current, now)
        : _exitDefrostInternal(current, now);
    _freezers[freezerId] = updated;
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
          peakTemp: temp,
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

          final preStart = state.copyWith(
            isDoorOpen: false,
            baselineTemp: baseline,
            peakTemp: peakTemp,
            lastDoorOpenTemp: openedTemp,
            lastDoorCloseTemp: temp,
            lastDoorCloseAt: now,
            doorTransitions: transitions,
          );
          _freezers[id] = preStart;

          unawaited(
            _startAdaptiveCycleInternal(
              freezerId: id,
              baselineTemp: baseline,
              peakTemp: peakTemp,
            ),
          );

          return _freezers[id] ?? preStart;
        }

        final afterInspect = state.copyWith(
          isDoorOpen: false,
          baselineTemp: state.baselineTemp ?? openedTemp,
          peakTemp: recordedPeak,
          lastDoorOpenTemp: openedTemp,
          lastDoorCloseTemp: temp,
          lastDoorCloseAt: now,
          doorTransitions: transitions,
        );
        unawaited(_persistThermalSnapshot(afterInspect));
        return afterInspect;
      }

      // CASO 2: Estava em RESFRIAMENTO (COOLING ou DOOR_OPEN)
      if (state.status == FreezerStatusEnum.cooling ||
          state.status == FreezerStatusEnum.doorOpen) {
        if (openSeconds >= state.reloadMinSeconds) {
          final preReload = state.copyWith(
            isDoorOpen: false,
            status: FreezerStatusEnum.cooling,
            peakTemp: recordedPeak,
            lastDoorOpenTemp: openedTemp,
            lastDoorCloseTemp: temp,
            lastDoorCloseAt: now,
            doorTransitions: transitions,
          );
          _freezers[id] = preReload;

          unawaited(
            _startAdaptiveCycleInternal(
              freezerId: id,
              baselineTemp: state.baselineTemp ?? openedTemp,
              peakTemp: recordedPeak,
            ),
          );
          return _freezers[id] ?? preReload;
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
            expectedDurationSeconds: newExpected,
            accumulatedDoorOpenSeconds: newAccDoorOpen,
            accumulatedPenaltySeconds: newAccPenalty,
            doorOpenCount: newDoorOpenCount,
          );
        }

        final afterPenalty = state.copyWith(
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
          lastDoorCloseAt: now,
          doorTransitions: transitions,
        );
        unawaited(_persistActiveCyclePrefs(afterPenalty));
        unawaited(_persistThermalSnapshot(afterPenalty));
        return afterPenalty;
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
          final newExpected = state.expectedDurationSeconds + extraSec;
          if (state.activeCycleId != null) {
            _freezerDao.updateCoolingCycleMetrics(
              cycleId: state.activeCycleId!,
              expectedDurationSeconds: newExpected,
              accumulatedDoorOpenSeconds:
                  state.accumulatedDoorOpenSeconds + openSeconds,
              accumulatedPenaltySeconds:
                  state.accumulatedPenaltySeconds + penaltySec,
              doorOpenCount: state.doorOpenCount + 1,
            );
          }
          final afterSoftDoor = state.copyWith(
            isDoorOpen: false,
            status: FreezerStatusEnum.cooling,
            expectedDurationSeconds: newExpected,
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
            lastDoorCloseAt: now,
            doorTransitions: transitions,
          );
          unawaited(_persistActiveCyclePrefs(afterSoftDoor));
          unawaited(_persistThermalSnapshot(afterSoftDoor));
          return afterSoftDoor;
        }

        if (openSeconds >= state.reloadMinSeconds) {
          final preReadyReload = state.copyWith(
            isDoorOpen: false,
            status: FreezerStatusEnum.cooling,
            peakTemp: recordedPeak,
            lastDoorOpenTemp: openedTemp,
            lastDoorCloseTemp: temp,
            lastDoorCloseAt: now,
            doorTransitions: transitions,
          );
          _freezers[id] = preReadyReload;
          unawaited(
            recordFeedback(id, FreezerFeedbackEnum.autoOk).then((_) {
              return _startAdaptiveCycleInternal(
                freezerId: id,
                baselineTemp: state.baselineTemp ?? openedTemp,
                peakTemp: recordedPeak,
              );
            }),
          );
          return _freezers[id] ?? preReadyReload;
        }

        final afterReadyClose = state.copyWith(
          isDoorOpen: false,
          status: FreezerStatusEnum.feedbackPending,
          feedbackCountdownSeconds: 30,
          peakTemp: recordedPeak,
          lastDoorOpenTemp: openedTemp,
          lastDoorCloseTemp: temp,
          lastDoorCloseAt: now,
          doorTransitions: transitions,
        );
        unawaited(_persistThermalSnapshot(afterReadyClose));
        return afterReadyClose;
      }

      final afterClose = state.copyWith(
        isDoorOpen: false,
        peakTemp: recordedPeak,
        lastDoorOpenTemp: openedTemp,
        lastDoorCloseTemp: temp,
        lastDoorCloseAt: now,
        doorTransitions: transitions,
      );
      unawaited(_persistThermalSnapshot(afterClose));
      return afterClose;
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
          if (s.isDefrosting &&
              (s.status == FreezerStatusEnum.cooling ||
                  s.status == FreezerStatusEnum.doorOpen)) {
            // Congela o progresso de cristalização durante o degelo (Frost Free desligado):
            // elapsedSeconds e remainingSeconds ficam pausados, e expectedDurationSeconds
            // acompanha 1s a cada 1s de degelo para o operador visualizar o impacto real no alvo.
            final defrostSec = s.defrostStartedAt != null
                ? max(1, now.difference(s.defrostStartedAt!).inSeconds)
                : s.currentDefrostSeconds + 1;
            final newAccDefrost = s.accumulatedDefrostSeconds + 1;
            final newExpected = s.expectedDurationSeconds + 1;

            s = s.copyWith(
              currentDefrostSeconds: defrostSec,
              accumulatedDefrostSeconds: newAccDefrost,
              expectedDurationSeconds: newExpected,
            );
            _freezers[id] = s;
            changed = true;
          } else {
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
          }
        } else if (s.isDefrosting) {
          final defrostSec = s.defrostStartedAt != null
              ? max(1, now.difference(s.defrostStartedAt!).inSeconds)
              : s.currentDefrostSeconds + 1;
          s = s.copyWith(currentDefrostSeconds: defrostSec);
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
    int initialElapsedSeconds = 0,
  }) async {
    final current = _freezers[freezerId];
    if (current == null) return;

    final activeBatch = _productionRepo.currentActiveBatch;
    final baseSeconds = current.calibratedBaseSeconds;
    final safeElapsed = max(0, initialElapsedSeconds);
    final initialRemaining = max(0, baseSeconds - safeElapsed);
    final initialStatus = initialRemaining == 0
        ? FreezerStatusEnum.ready
        : FreezerStatusEnum.cooling;
    final effectiveStartedAt = DateTime.now().subtract(
      Duration(seconds: safeElapsed),
    );

    // 1. Hot Path (0ms): Atualiza estado em memória imediatamente antes do await do SQLite
    _cycleStartedAt[freezerId] = effectiveStartedAt;
    _executedSecondsInCycle[freezerId] = safeElapsed;
    final updatedImmediate = current.copyWith(
      status: initialStatus,
      expectedDurationSeconds: baseSeconds,
      remainingSeconds: initialRemaining,
      elapsedSeconds: safeElapsed,
      baselineTemp: baselineTemp,
      peakTemp: peakTemp,
      accumulatedPenaltySeconds: 0,
      accumulatedDoorOpenSeconds: 0,
      doorOpenCount: 0,
      accumulatedDefrostSeconds: 0,
      clearFeedbackCountdown: true,
      calibratedBaseSeconds: baseSeconds,
    );
    _freezers[freezerId] = updatedImmediate;
    _emitState();

    unawaited(_persistActiveCyclePrefs(updatedImmediate, startedAt: effectiveStartedAt));
    unawaited(_persistThermalSnapshot(updatedImmediate));

    // 2. Warm Path: Persiste no SQLite garantindo que f1/f2 existam na tabela pai
    await _freezerDao.ensureSensorFreezersExist();
    final startRes = await _freezerDao.startCoolingCycle(
      batchId: activeBatch?.id,
      freezerId: freezerId,
      expectedSeconds: baseSeconds,
      startedAt: effectiveStartedAt,
      baselineTemp: baselineTemp,
      initialPeakTemp: peakTemp,
    );

    final cycleId = startRes.valueOrNull;
    final latest = _freezers[freezerId];
    if (latest != null && cycleId != null) {
      _freezers[freezerId] = latest.copyWith(activeCycleId: cycleId);
      _emitState();
    }

    if (initialStatus == FreezerStatusEnum.ready) {
      if (!_cycleReadyController.isClosed) {
        _cycleReadyController.add(freezerId);
      }
    } else if (!_cycleStartedController.isClosed) {
      _cycleStartedController.add(freezerId);
    }
  }

  /// Inicia um novo ciclo descontando o tempo já decorrido desde o último fechamento da porta.
  /// Se o lote anterior estava pronto (`ready`) ou aguardando avaliação (`feedbackPending`),
  /// registra automaticamente o lote anterior como `autoOk` antes de iniciar o novo ciclo.
  Future<void> startCycleFromLastDoorClose(String freezerId) async {
    final current = _freezers[freezerId];
    if (current == null) return;

    if (current.status == FreezerStatusEnum.ready ||
        current.status == FreezerStatusEnum.feedbackPending) {
      await recordFeedback(freezerId, FreezerFeedbackEnum.autoOk);
    }

    final refreshed = _freezers[freezerId] ?? current;
    final lastClose =
        refreshed.lastDoorCloseAt ??
        refreshed.doorTransitions
            .where((t) => !t.isOpen)
            .lastOrNull
            ?.timestamp;

    final elapsedSinceClose = lastClose != null
        ? max(0, DateTime.now().difference(lastClose).inSeconds)
        : 0;

    await _startAdaptiveCycleInternal(
      freezerId: freezerId,
      baselineTemp: refreshed.effectiveBaselineTemp,
      peakTemp: refreshed.effectivePeakTemp,
      initialElapsedSeconds: elapsedSinceClose,
    );
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

      final newExpected = current.expectedDurationSeconds + extensionSec;
      if (current.activeCycleId != null) {
        await _freezerDao.updateCoolingCycleMetrics(
          cycleId: current.activeCycleId!,
          expectedDurationSeconds: newExpected,
          accumulatedDoorOpenSeconds: current.accumulatedDoorOpenSeconds,
          accumulatedPenaltySeconds: current.accumulatedPenaltySeconds,
          doorOpenCount: current.doorOpenCount,
        );
      }

      final afterSoft = current.copyWith(
        status: FreezerStatusEnum.cooling,
        expectedDurationSeconds: newExpected,
        remainingSeconds: extensionSec,
        elapsedSeconds: executedSeconds,
        clearFeedbackCountdown: true,
        lastFeedback: feedback,
        calibratedBaseSeconds: newCalibrated,
        isCalibrated: true,
      );
      _freezers[freezerId] = afterSoft;
      unawaited(_persistActiveCyclePrefs(afterSoft));

      _emitState();
      return;
    }

    if (current.activeCycleId != null) {
      final totalWallSeconds =
          executedSeconds + current.accumulatedDefrostSeconds;
      await _freezerDao.finishCoolingCycle(
        cycleId: current.activeCycleId!,
        actualSeconds: totalWallSeconds,
        accumulatedDoorOpenSeconds: current.accumulatedDoorOpenSeconds,
        accumulatedPenaltySeconds: current.accumulatedPenaltySeconds,
        doorOpenCount: current.doorOpenCount,
        accumulatedDefrostSeconds: current.accumulatedDefrostSeconds,
        feedback: feedback.code,
      );
    } else {
      await _freezerDao.cancelActiveCoolingCycles(freezerId);
    }

    // Protege a calibração automática: se o ciclo sofreu pausa por degelo (Frost Free desligado),
    // não altera o tempo base calibrado dos próximos ciclos para que um degelo de ~20-30 min
    // não distorça o tempo normal de 10-12 min das próximas fornadas.
    final hadDefrostAnomaly =
        current.isDefrosting || current.accumulatedDefrostSeconds > 0;
    final newCalibrated = hadDefrostAnomaly
        ? current.calibratedBaseSeconds
        : _engine.adaptCalibration(
            currentCalibratedSeconds: current.calibratedBaseSeconds,
            executedEffectiveSeconds: executedSeconds,
            feedback: feedback,
          );

    if (!hadDefrostAnomaly) {
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
    }

    _cycleStartedAt.remove(freezerId);
    _executedSecondsInCycle.remove(freezerId);
    unawaited(_clearActiveCyclePrefs(freezerId));
    _freezers[freezerId] = current.copyWith(
      status: FreezerStatusEnum.idle,
      remainingSeconds: newCalibrated,
      expectedDurationSeconds: newCalibrated,
      elapsedSeconds: 0,
      accumulatedDefrostSeconds: 0,
      clearFeedbackCountdown: true,
      clearActiveCycleId: true,
      lastFeedback: feedback,
      calibratedBaseSeconds: newCalibrated,
      isCalibrated: true,
    );

    _emitState();
  }

  /// Cancela o ciclo em andamento (Freezer Vazio / Sem Ovos), voltando para idle sem alterar a calibração
  void cancelCycle(String freezerId) {
    final current = _freezers[freezerId];
    if (current == null) return;

    _cycleStartedAt.remove(freezerId);
    _executedSecondsInCycle.remove(freezerId);
    unawaited(_freezerDao.cancelActiveCoolingCycles(freezerId));
    unawaited(_clearActiveCyclePrefs(freezerId));

    _freezers[freezerId] = current.copyWith(
      status: FreezerStatusEnum.idle,
      elapsedSeconds: 0,
      remainingSeconds: current.calibratedBaseSeconds,
      expectedDurationSeconds: current.calibratedBaseSeconds,
      accumulatedPenaltySeconds: 0,
      accumulatedDoorOpenSeconds: 0,
      doorOpenCount: 0,
      accumulatedDefrostSeconds: 0,
      clearFeedbackCountdown: true,
      clearActiveCycleId: true,
    );

    _emitState();
  }

  Future<void> _persistActiveCyclePrefs(
    FreezerLiveState state, {
    DateTime? startedAt,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = state.freezerId;
      final resolvedStart =
          startedAt ??
          _cycleStartedAt[id] ??
          DateTime.now().subtract(Duration(seconds: state.elapsedSeconds));
      await prefs.setInt(
        'freezer_${id}_active_start_ms',
        resolvedStart.millisecondsSinceEpoch,
      );
      await prefs.setInt(
        'freezer_${id}_active_expected_sec',
        state.expectedDurationSeconds,
      );
      if (state.baselineTemp != null) {
        await prefs.setDouble(
          'freezer_${id}_active_base_temp',
          state.baselineTemp!,
        );
      }
      if (state.peakTemp != null) {
        await prefs.setDouble(
          'freezer_${id}_active_peak_temp',
          state.peakTemp!,
        );
      }
    } catch (_) {}
  }

  Future<void> _clearActiveCyclePrefs(String freezerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('freezer_${freezerId}_active_start_ms');
      await prefs.remove('freezer_${freezerId}_active_expected_sec');
      await prefs.remove('freezer_${freezerId}_active_base_temp');
      await prefs.remove('freezer_${freezerId}_active_peak_temp');
    } catch (_) {}
  }

  Future<void> _persistDefrostPrefs(FreezerLiveState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = state.freezerId;
      await prefs.setBool('freezer_${id}_is_defrosting', state.isDefrosting);
      if (state.defrostStartedAt != null) {
        await prefs.setInt(
          'freezer_${id}_defrost_start_ms',
          state.defrostStartedAt!.millisecondsSinceEpoch,
        );
      }
      if (state.defrostStartTemp != null) {
        await prefs.setDouble(
          'freezer_${id}_defrost_start_temp',
          state.defrostStartTemp!,
        );
      }
      if (state.defrostPeakTemp != null) {
        await prefs.setDouble(
          'freezer_${id}_defrost_peak_temp',
          state.defrostPeakTemp!,
        );
      }
    } catch (_) {}
  }

  Future<void> _clearDefrostPrefs(String freezerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('freezer_${freezerId}_is_defrosting');
      await prefs.remove('freezer_${freezerId}_defrost_start_ms');
      await prefs.remove('freezer_${freezerId}_defrost_start_temp');
      await prefs.remove('freezer_${freezerId}_defrost_peak_temp');
    } catch (_) {}
  }

  Future<void> _persistThermalSnapshot(FreezerLiveState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = state.freezerId;
      await prefs.setDouble('freezer_${id}_last_temp', state.currentTemp);
      if (state.lastDoorOpenTemp != null) {
        await prefs.setDouble(
          'freezer_${id}_last_open_temp',
          state.lastDoorOpenTemp!,
        );
      }
      if (state.lastDoorCloseTemp != null) {
        await prefs.setDouble(
          'freezer_${id}_last_close_temp',
          state.lastDoorCloseTemp!,
        );
      }
      if (state.lastDoorCloseAt != null) {
        await prefs.setInt(
          'freezer_${id}_last_close_ms',
          state.lastDoorCloseAt!.millisecondsSinceEpoch,
        );
      }
    } catch (_) {}
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
    _defrostToggleController.close();
  }
}

void unawaited(Future<void> future) {}
