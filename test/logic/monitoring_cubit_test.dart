import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/data/services/audio_service.dart';
import 'package:gm_fabrica_monitoramento/data/services/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/logic/monitoring/monitoring_cubit.dart';
import 'package:gm_fabrica_monitoramento/logic/settings/settings_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeWebSocketService implements IWebSocketService {
  final messageController = StreamController<Map<String, dynamic>>.broadcast();
  final statusController = StreamController<ConnectionStatus>.broadcast();
  final errorController = StreamController<String?>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;

  @override
  Stream<Map<String, dynamic>> get messageStream => messageController.stream;

  @override
  Stream<ConnectionStatus> get statusStream => statusController.stream;

  @override
  Stream<String?> get errorStream => errorController.stream;

  @override
  ConnectionStatus get currentStatus => _status;

  @override
  String? get lastErrorMessage => null;

  @override
  void connect(String url) {
    _status = ConnectionStatus.connected;
    statusController.add(_status);
  }

  @override
  void disconnect() {
    _status = ConnectionStatus.disconnected;
    statusController.add(_status);
  }

  @override
  void dispose() {
    messageController.close();
    statusController.close();
    errorController.close();
  }

  void emitMessage(Map<String, dynamic> msg) {
    messageController.add(msg);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeWebSocketService fakeWs;
  late SettingsCubit settingsCubit;
  late AudioService audioService;
  late MonitoringCubit monitoringCubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeWs = FakeWebSocketService();
    settingsCubit = SettingsCubit();
    audioService = AudioService(isMuted: true); // Muted during tests
    monitoringCubit = MonitoringCubit(
      settingsCubit: settingsCubit,
      audioService: audioService,
      webSocketService: fakeWs,
    );
  });

  tearDown(() async {
    await monitoringCubit.close();
    fakeWs.dispose();
  });

  group('MonitoringCubit Tests', () {
    test('Initial state has no freezers until data is received', () {
      expect(monitoringCubit.state.rawEggCount, 0);
      expect(monitoringCubit.state.batchEggCount, 0);
      expect(monitoringCubit.state.freezer1, isNull);
      expect(monitoringCubit.state.freezer2, isNull);
      expect(monitoringCubit.state.activeFreezers, isEmpty);
    });

    test('Processes frame with only 1 freezer without creating dummy freezers', () async {
      fakeWs.emitMessage({
        't': 'telem',
        'up': 5000,
        'c': 10,
        'f1': {'temp': 4.5, 'd': 0, 'ok': 1},
      });
      await pumpEventQueue();

      expect(monitoringCubit.state.freezer1, isNotNull);
      expect(monitoringCubit.state.freezer1!.currentTemp, 4.5);
      expect(monitoringCubit.state.freezer2, isNull);
      expect(monitoringCubit.state.activeFreezers.length, 1);
    });

    test('Processes TelemetryFrame and records baseline temperature', () async {
      fakeWs.emitMessage({
        't': 'telem',
        'up': 10000,
        'c': 50,
        'f1': {'temp': 4.0, 'd': 0, 'ok': 1},
        'f2': {'temp': -18.0, 'd': 0, 'ok': 1},
      });

      await pumpEventQueue();

      expect(monitoringCubit.state.uptimeMs, 10000);
      expect(monitoringCubit.state.rawEggCount, 50);
      expect(monitoringCubit.state.freezer1?.currentTemp, 4.0);
      expect(monitoringCubit.state.freezer1?.baselineTemp, 4.0);
      expect(monitoringCubit.state.freezer1?.temperatureDelta, 0.0);
      expect(monitoringCubit.state.freezer2?.currentTemp, -18.0);
      expect(monitoringCubit.state.activeFreezers.length, 2);
    });

    test('Door opening establishes new baseline and tracks temperature loss', () async {
      // Step 1: Normal closed state at 4.0 °C
      fakeWs.emitMessage({
        't': 'telem',
        'up': 1000,
        'c': 10,
        'f1': {'temp': 4.0, 'd': 0, 'ok': 1},
        'f2': {'temp': -18.0, 'd': 0, 'ok': 1},
      });
      await pumpEventQueue();

      // Step 2: Door opens at 4.2 °C
      fakeWs.emitMessage({
        't': 'telem',
        'up': 2000,
        'c': 10,
        'f1': {'temp': 4.2, 'd': 1, 'ok': 1},
        'f2': {'temp': -18.0, 'd': 0, 'ok': 1},
      });
      await pumpEventQueue();

      expect(monitoringCubit.state.freezer1!.isDoorOpen, true);
      expect(monitoringCubit.state.freezer1!.baselineTemp, 4.2);

      // Step 3: Temperature warms up to 5.5 °C while open
      fakeWs.emitMessage({
        't': 'telem',
        'up': 3000,
        'c': 10,
        'f1': {'temp': 5.5, 'd': 1, 'ok': 1},
        'f2': {'temp': -18.0, 'd': 0, 'ok': 1},
      });
      await pumpEventQueue();

      // Loss of cold = 5.5 - 4.2 = 1.3 °C
      expect(monitoringCubit.state.freezer1!.temperatureDelta, closeTo(1.3, 0.001));
    });

    test('Hit event increments egg count immediately', () async {
      fakeWs.emitMessage({'t': 'hit', 'c': 99});
      await pumpEventQueue();

      expect(monitoringCubit.state.rawEggCount, 99);
      expect(monitoringCubit.state.batchEggCount, 99);
      expect(monitoringCubit.state.isHitAnimating, true);
    });

    test('Batch reset zeroes batchEggCount relative to current raw count', () async {
      fakeWs.emitMessage({'t': 'hit', 'c': 120});
      await pumpEventQueue();

      expect(monitoringCubit.state.rawEggCount, 120);
      expect(monitoringCubit.state.batchEggCount, 120);

      monitoringCubit.resetBatch();

      expect(monitoringCubit.state.rawEggCount, 120);
      expect(monitoringCubit.state.batchEggCount, 0);

      // Next hit
      fakeWs.emitMessage({'t': 'hit', 'c': 121});
      await pumpEventQueue();

      expect(monitoringCubit.state.rawEggCount, 121);
      expect(monitoringCubit.state.batchEggCount, 1);
    });

    test('Probe failure is reflected in state', () async {
      fakeWs.emitMessage({
        't': 'telem',
        'up': 5000,
        'c': 20,
        'f1': {'temp': 4.0, 'd': 0, 'ok': 1},
        'f2': {'temp': -18.0, 'd': 0, 'ok': 0}, // Probe failed!
      });
      await pumpEventQueue();

      expect(monitoringCubit.state.freezer1!.isProbeOk, true);
      expect(monitoringCubit.state.freezer2!.isProbeOk, false);
    });

    test('Connection error emits message without crashing the cubit', () async {
      fakeWs.errorController.add('Não foi possível conectar ao Arduino.');
      await pumpEventQueue();

      expect(
        monitoringCubit.state.connectionErrorMessage,
        'Não foi possível conectar ao Arduino.',
      );

      // System remains alive and can still receive telemetry or hits
      fakeWs.emitMessage({'t': 'hit', 'c': 55});
      await pumpEventQueue();

      expect(monitoringCubit.state.rawEggCount, 55);
    });

    test('Box automatically completes and resets when reaching capacity', () async {
      monitoringCubit.setBoxCapacity(50);
      expect(monitoringCubit.state.currentBoxCount, 0);
      expect(monitoringCubit.state.completedBoxesCount, 0);

      // Hit 49 eggs
      for (int i = 1; i <= 49; i++) {
        monitoringCubit.incrementEggManual();
      }
      expect(monitoringCubit.state.currentBoxCount, 49);
      expect(monitoringCubit.state.completedBoxesCount, 0);

      // Hit 50th egg -> triggers box completion!
      monitoringCubit.incrementEggManual();
      expect(monitoringCubit.state.completedBoxesCount, 1);
      expect(monitoringCubit.state.currentBoxCount, 0);
      expect(monitoringCubit.state.dailyTotalEggs, 50);
      expect(monitoringCubit.state.isBoxJustCompleted, true);
    });

    test('Manual adjustment (+1 and -1) updates box and daily count correctly', () {
      monitoringCubit.setBoxCapacity(40);
      monitoringCubit.incrementEggManual();
      monitoringCubit.incrementEggManual();

      expect(monitoringCubit.state.currentBoxCount, 2);
      expect(monitoringCubit.state.dailyTotalEggs, 2);

      monitoringCubit.decrementEggManual();
      expect(monitoringCubit.state.currentBoxCount, 1);
      expect(monitoringCubit.state.dailyTotalEggs, 1);
    });

    test('Freezer feedback can be recorded and returns state to cooling', () async {
      fakeWs.emitMessage({
        't': 'telem',
        'up': 5000,
        'c': 20,
        'f1': {'temp': 4.0, 'd': 0, 'ok': 1},
      });
      await pumpEventQueue();

      monitoringCubit.recordFreezerFeedback('f1', 'No ponto');
      expect(monitoringCubit.state.freezer1!.lastFeedback, 'No ponto');
      expect(monitoringCubit.state.freezer1!.batchStatus.isCooling, true);
    });
  });
}

