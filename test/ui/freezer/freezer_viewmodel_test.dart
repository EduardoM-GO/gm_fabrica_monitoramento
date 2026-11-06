import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/data/repositories/websocket_repository_impl.dart';
import 'package:gm_fabrica_monitoramento/data/services/audio_service.dart';
import 'package:gm_fabrica_monitoramento/data/services/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/domain/entities/freezer_telemetry_entity.dart';
import 'package:gm_fabrica_monitoramento/domain/repositories/i_freezer_repository.dart';
import 'package:gm_fabrica_monitoramento/src/ui/freezer/view_models/freezer_viewmodel.dart';
import 'package:gm_fabrica_monitoramento/src/ui/settings/view_models/settings_viewmodel.dart';

class FakeFreezerRepository implements IFreezerRepository {
  final List<FreezerTelemetryLogEntity> recordedLogs = [];

  @override
  Future<void> recordTelemetryLog(FreezerTelemetryLogEntity log) async {
    recordedLogs.add(log);
  }

  @override
  Future<List<FreezerTelemetryLogEntity>> getRecentLogs({
    required String freezerId,
    int limit = 60,
  }) async {
    return recordedLogs.where((l) => l.freezerId == freezerId).toList();
  }

  @override
  Stream<List<FreezerTelemetryLogEntity>> watchRecentLogs({
    required String freezerId,
    int limit = 60,
  }) {
    return Stream.value(
      recordedLogs.where((l) => l.freezerId == freezerId).toList(),
    );
  }
}

class FakeWebSocketService implements IWebSocketService {
  final messageController = StreamController<Map<String, dynamic>>.broadcast();
  final statusController = StreamController<ConnectionStatus>.broadcast();
  final errorController = StreamController<String?>.broadcast();

  @override
  Stream<Map<String, dynamic>> get messageStream => messageController.stream;
  @override
  Stream<ConnectionStatus> get statusStream => statusController.stream;
  @override
  Stream<String?> get errorStream => errorController.stream;
  @override
  ConnectionStatus get currentStatus => ConnectionStatus.connected;
  @override
  String? get lastErrorMessage => null;
  @override
  void connect(String url) {}
  @override
  void disconnect() {}
  @override
  void dispose() {
    messageController.close();
    statusController.close();
    errorController.close();
  }
}

void main() {
  late FakeFreezerRepository fakeFreezerRepo;
  late FakeWebSocketService fakeWsService;
  late WebSocketRepositoryImpl webSocketRepo;
  late AudioService audioService;
  late SettingsViewModel settingsViewModel;
  late FreezerViewModel freezerViewModel;

  setUp(() {
    fakeFreezerRepo = FakeFreezerRepository();
    fakeWsService = FakeWebSocketService();
    webSocketRepo = WebSocketRepositoryImpl(service: fakeWsService);
    audioService = AudioService(isMuted: true);
    settingsViewModel = SettingsViewModel();

    freezerViewModel = FreezerViewModel(
      freezerRepo: fakeFreezerRepo,
      webSocketRepo: webSocketRepo,
      audioService: audioService,
      settingsViewModel: settingsViewModel,
    );
  });

  tearDown(() {
    freezerViewModel.dispose();
    settingsViewModel.dispose();
    webSocketRepo.dispose();
    fakeWsService.dispose();
  });

  group('FreezerViewModel MVVM Tests', () {
    test('Initial state has no active freezers until data is received', () {
      expect(freezerViewModel.state.activeFreezers, isEmpty);
      expect(freezerViewModel.state.freezer1, isNull);
      expect(freezerViewModel.state.freezer2, isNull);
    });

    test(
      'Processes frame with only 1 freezer without creating dummy freezers',
      () async {
        fakeWsService.messageController.add({
          't': 'telem',
          'up': 1000,
          'c': 0,
          'f1': {'temp': 3.5, 'd': 0, 'ok': 1},
        });
        await pumpEventQueue();

        expect(freezerViewModel.state.activeFreezers.length, equals(1));
        expect(freezerViewModel.state.freezer1, isNotNull);
        expect(freezerViewModel.state.freezer1!.currentTemp, equals(3.5));
        expect(freezerViewModel.state.freezer2, isNull);
      },
    );

    test('Processes frame with 2 freezers and updates history', () async {
      fakeWsService.messageController.add({
        't': 'telem',
        'up': 2000,
        'c': 0,
        'f1': {'temp': 3.5, 'd': 0, 'ok': 1},
        'f2': {'temp': -18.2, 'd': 0, 'ok': 1},
      });
      await pumpEventQueue();

      expect(freezerViewModel.state.activeFreezers.length, equals(2));
      expect(freezerViewModel.state.freezer1!.currentTemp, equals(3.5));
      expect(freezerViewModel.state.freezer2!.currentTemp, equals(-18.2));
      expect(freezerViewModel.state.freezer1!.history, isNotEmpty);
    });

    test(
      'Door opening changes batch status to doorOpen and tracks loss',
      () async {
        // 1. Freezer starts closed at 3.0 C
        fakeWsService.messageController.add({
          't': 'telem',
          'up': 1000,
          'c': 0,
          'f1': {'temp': 3.0, 'd': 0, 'ok': 1},
        });
        await pumpEventQueue();
        expect(freezerViewModel.state.freezer1!.isDoorOpen, isFalse);

        // 2. Door opens at 4.2 C
        fakeWsService.messageController.add({
          't': 'telem',
          'up': 2000,
          'c': 0,
          'f1': {'temp': 4.2, 'd': 1, 'ok': 1},
        });
        await pumpEventQueue();

        final f1 = freezerViewModel.state.freezer1!;
        expect(f1.isDoorOpen, isTrue);
        expect(f1.batchStatus, equals(FreezerBatchStatus.doorOpen));
      },
    );

    test('Probe failure immediately triggers critical alert level', () async {
      fakeWsService.messageController.add({
        't': 'telem',
        'up': 1000,
        'c': 0,
        'f1': {'temp': 0.0, 'd': 0, 'ok': 0}, // ok == 0 means sensor error
      });
      await pumpEventQueue();

      final f1 = freezerViewModel.state.freezer1!;
      expect(f1.isProbeOk, isFalse);
      expect(f1.alertLevel, equals(DoorAlertLevel.critical));
    });

    test('Feedback prompt and recording returns state to cooling', () async {
      fakeWsService.messageController.add({
        't': 'telem',
        'up': 1000,
        'c': 0,
        'f1': {'temp': 3.0, 'd': 0, 'ok': 1},
      });
      await pumpEventQueue();

      freezerViewModel.recordFreezerFeedback('f1', 'No ponto');
      await pumpEventQueue();

      final f1 = freezerViewModel.state.freezer1!;
      expect(f1.batchStatus, equals(FreezerBatchStatus.cooling));
      expect(f1.lastFeedback, equals('No ponto'));
    });
  });
}
