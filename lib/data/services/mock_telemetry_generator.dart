import 'dart:async';
import 'dart:math';
import 'websocket_service.dart';

class MockWebSocketService implements IWebSocketService {
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _errorController = StreamController<String?>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  Timer? _telemetryTimer;
  Timer? _hitRandomTimer;

  int _uptimeMs = 120000;
  int _eggCount = 142;

  // Freezer 1 initial state (cooling chamber: target around 4.0 °C)
  double _f1Temp = 4.2;
  int _f1Door = 0; // closed
  int _f1Ok = 1;

  // Freezer 2 initial state (deep freeze: target around -18.0 °C)
  double _f2Temp = -18.5;
  int _f2Door = 0; // closed
  int _f2Ok = 1;
  bool includeSecondFreezer = false; // By default simulate only 1 freezer matching current hardware setup

  final Random _rng = Random();

  @override
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  @override
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  @override
  Stream<String?> get errorStream => _errorController.stream;

  @override
  ConnectionStatus get currentStatus => _status;

  @override
  String? get lastErrorMessage => null;

  @override
  void connect(String url) {
    _status = ConnectionStatus.connecting;
    _statusController.add(_status);

    Future.delayed(const Duration(milliseconds: 400), () {
      _status = ConnectionStatus.connected;
      _statusController.add(_status);
      _startTimers();
    });
  }

  void _startTimers() {
    _stopTimers();

    // 1-second periodic telemetry loop
    _telemetryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _uptimeMs += 1000;

      // Realistic temperature physics
      // Freezer 1
      if (_f1Door == 1) {
        _f1Temp += 0.08 + (_rng.nextDouble() * 0.04); // warming up when door open
      } else {
        if (_f1Temp > 4.0) {
          _f1Temp -= 0.03 + (_rng.nextDouble() * 0.02); // cooling back to target
        } else {
          _f1Temp += (_rng.nextDouble() - 0.5) * 0.05; // slight natural jitter
        }
      }

      // Freezer 2
      if (_f2Door == 1) {
        _f2Temp += 0.12 + (_rng.nextDouble() * 0.06); // warming up faster when open
      } else {
        if (_f2Temp > -18.0) {
          _f2Temp -= 0.04 + (_rng.nextDouble() * 0.03); // cooling back to target
        } else {
          _f2Temp += (_rng.nextDouble() - 0.5) * 0.04; // slight natural jitter
        }
      }

      final telemFrame = <String, dynamic>{
        't': 'telem',
        'up': _uptimeMs,
        'c': _eggCount,
        'f1': {
          'temp': double.parse(_f1Temp.toStringAsFixed(2)),
          'd': _f1Door,
          'ok': _f1Ok,
        },
        if (includeSecondFreezer)
          'f2': {
            'temp': double.parse(_f2Temp.toStringAsFixed(2)),
            'd': _f2Door,
            'ok': _f2Ok,
          },
      };

      if (!_messageController.isClosed) {
        _messageController.add(telemFrame);
      }
    });

    // Random egg hits every 3 to 7 seconds
    _scheduleNextRandomHit();
  }

  void _scheduleNextRandomHit() {
    final nextSec = 3 + _rng.nextInt(4);
    _hitRandomTimer?.cancel();
    _hitRandomTimer = Timer(Duration(seconds: nextSec), () {
      triggerEggHit();
      if (_status == ConnectionStatus.connected) {
        _scheduleNextRandomHit();
      }
    });
  }

  /// Manually simulates an egg passing the chute
  void triggerEggHit() {
    _eggCount++;
    final hitFrame = {
      't': 'hit',
      'c': _eggCount,
    };
    if (!_messageController.isClosed) {
      _messageController.add(hitFrame);
    }
  }

  /// Toggles a freezer door for interactive testing
  void toggleDoor(int freezerNum) {
    if (freezerNum == 1) {
      _f1Door = _f1Door == 0 ? 1 : 0;
    } else if (freezerNum == 2) {
      _f2Door = _f2Door == 0 ? 1 : 0;
    }
  }

  /// Toggles a probe failure for interactive testing
  void toggleProbe(int freezerNum) {
    if (freezerNum == 1) {
      _f1Ok = _f1Ok == 1 ? 0 : 1;
    } else if (freezerNum == 2) {
      _f2Ok = _f2Ok == 1 ? 0 : 1;
    }
  }

  void _stopTimers() {
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
    _hitRandomTimer?.cancel();
    _hitRandomTimer = null;
  }

  @override
  void disconnect() {
    _stopTimers();
    _status = ConnectionStatus.disconnected;
    _statusController.add(_status);
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
    _errorController.close();
  }
}

