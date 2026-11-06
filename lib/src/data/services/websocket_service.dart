import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

abstract class IWebSocketService {
  Stream<Map<String, dynamic>> get messageStream;
  Stream<ConnectionStatus> get statusStream;
  Stream<String?> get errorStream;
  ConnectionStatus get currentStatus;
  String? get lastErrorMessage;
  void connect(String url);
  void disconnect();
  void dispose();
}

class WebSocketServiceImpl implements IWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _reconnectTimer;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _errorController = StreamController<String?>.broadcast();

  ConnectionStatus _currentStatus = ConnectionStatus.disconnected;
  String? _lastErrorMessage;
  String? _lastUrl;
  bool _isDisposed = false;
  int _reconnectAttempts = 0;

  @override
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  @override
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  @override
  Stream<String?> get errorStream => _errorController.stream;

  @override
  ConnectionStatus get currentStatus => _currentStatus;

  @override
  String? get lastErrorMessage => _lastErrorMessage;

  void _updateStatus(ConnectionStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      if (!_statusController.isClosed) {
        _statusController.add(status);
      }
    }
  }

  void _setError(String? message) {
    _lastErrorMessage = message;
    if (!_errorController.isClosed) {
      _errorController.add(message);
    }
  }

  void _clearError() {
    _setError(null);
  }

  @override
  void connect(String url) {
    _lastUrl = url.trim();
    _reconnectAttempts = 0;
    _clearError();
    _internalConnect();
  }

  void _internalConnect() {
    if (_isDisposed || _lastUrl == null || _lastUrl!.isEmpty) return;

    _cleanupChannel();
    _updateStatus(
      _reconnectAttempts == 0 ? ConnectionStatus.connecting : ConnectionStatus.reconnecting,
    );

    try {
      final uri = Uri.parse(_lastUrl!);
      _channel = WebSocketChannel.connect(uri);

      // Handle channel.ready with timeout to prevent unhandled async exceptions and freezing
      _channel!.ready
          .timeout(const Duration(seconds: 4))
          .then((_) {
            if (!_isDisposed && _currentStatus != ConnectionStatus.connected) {
              _updateStatus(ConnectionStatus.connected);
              _clearError();
              _reconnectAttempts = 0;
            }
          })
          .catchError((error) {
            debugPrint('WebSocket connection attempt failed: $error');
            _setError('Não foi possível conectar ao Arduino em $_lastUrl (Inacessível ou offline).');
            _scheduleReconnect();
          });

      _channelSubscription = _channel!.stream.listen(
        (data) {
          if (_currentStatus != ConnectionStatus.connected) {
            _updateStatus(ConnectionStatus.connected);
            _clearError();
            _reconnectAttempts = 0;
          }
          try {
            final decoded = jsonDecode(data.toString());
            if (decoded is Map<String, dynamic>) {
              _messageController.add(decoded);
            }
          } catch (e) {
            debugPrint('Failed to parse incoming WebSocket message: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket stream error: $error');
          _setError('Conexão perdida com o Arduino em $_lastUrl. Reconectando...');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WebSocket connection closed.');
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('Failed to initiate WebSocket connection: $e');
      _setError('Endereço WebSocket inválido: $_lastUrl');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _cleanupChannel();
    _updateStatus(ConnectionStatus.reconnecting);

    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final delaySeconds = (_reconnectAttempts > 5) ? 5 : _reconnectAttempts * 1;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isDisposed) {
        _internalConnect();
      }
    });
  }

  void _cleanupChannel() {
    try {
      _channelSubscription?.cancel();
    } catch (_) {}
    _channelSubscription = null;

    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  @override
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cleanupChannel();
    _clearError();
    _updateStatus(ConnectionStatus.disconnected);
  }

  @override
  void dispose() {
    _isDisposed = true;
    disconnect();
    _messageController.close();
    _statusController.close();
    _errorController.close();
  }
}
