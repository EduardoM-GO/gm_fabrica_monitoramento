import 'dart:async';

import '../../domain/repositories/websocket_repository.dart';
import '../services/mock_telemetry_generator.dart';
import '../services/websocket_service.dart';

export '../../domain/repositories/websocket_repository.dart';

final class WebSocketRepositoryImpl implements IWebSocketRepository {
  final IWebSocketService service;
  final _hitController = StreamController<HitFrame>.broadcast();
  final _telemetryController = StreamController<TelemetryFrame>.broadcast();
  StreamSubscription? _msgSub;

  WebSocketRepositoryImpl({required this.service}) {
    _msgSub = service.messageStream.listen(_routeIncomingFrame);
  }

  void _routeIncomingFrame(Map<String, dynamic> json) {
    try {
      final frame = IncomingFrame.fromJson(json);
      if (frame is HitFrame) {
        if (!_hitController.isClosed) {
          _hitController.add(frame);
        }
      } else if (frame is TelemetryFrame) {
        if (!_telemetryController.isClosed) {
          _telemetryController.add(frame);
        }
      }
    } catch (_) {
      // Ignora silenciosamente frames com formato inválido para não quebrar o pipeline
    }
  }

  @override
  Stream<HitFrame> get hitStream => _hitController.stream;

  @override
  Stream<TelemetryFrame> get telemetryStream => _telemetryController.stream;

  @override
  Stream<ConnectionStatus> get connectionStatusStream => service.statusStream;

  @override
  Stream<String?> get errorStream => service.errorStream;

  @override
  ConnectionStatus get currentStatus => service.currentStatus;

  @override
  void connect(String url) => service.connect(url);

  @override
  void disconnect() => service.disconnect();

  @override
  void toggleSimulatorDoor(int freezerNum) {
    final s = service;
    if (s is MockWebSocketService) {
      s.toggleDoor(freezerNum);
    }
  }

  @override
  void toggleSimulatorProbe(int freezerNum) {
    final s = service;
    if (s is MockWebSocketService) {
      s.toggleProbe(freezerNum);
    }
  }

  @override
  void simulateEggHit() {
    final s = service;
    if (s is MockWebSocketService) {
      s.triggerEggHit();
    }
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _hitController.close();
    _telemetryController.close();
    service.dispose();
  }
}
