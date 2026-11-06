import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:gm_fabrica_monitoramento/src/data/websocket/enum/ws_connection_state_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/websocket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final class WebsocketServiceImpl implements WebsocketService {
  final _connectionStateController =
      StreamController<WsConnectionStateEnum>.broadcast();
  final _rawDataController = StreamController<BaseRawData>.broadcast();
  final _errorController = StreamController<String?>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _reconnectTimer;

  WsConnectionStateEnum _currentState = WsConnectionStateEnum.disconnected;
  bool _isDisposed = false;
  String _url = '';
  int _reconnectAttempts = 0;

  @override
  Future<void> connect(String host, int port) async {
    _url = 'ws://$host:$port';
    _reconnectAttempts = 0;
    _internalConnect();
  }

  Future<void> _internalConnect() async {
    if (_isDisposed) {
      return;
    }

    if (_currentState.isNotDisconnected) {
      await disconnect();
    }

    _updateStatus(
      _reconnectAttempts == 0
          ? WsConnectionStateEnum.connecting
          : WsConnectionStateEnum.reconnecting,
    );

    try {
      _updateStatus(WsConnectionStateEnum.connecting);
      _channel = WebSocketChannel.connect(Uri.parse(_url));

      _channelSubscription = _channel?.stream.listen(
        _onData,
        onError: (error) {
          _setError(
            error: error,
            tag: 'WebsocketServiceImpl._internalConnect.listen',
          );
          _scheduleReconnect();
        },
        onDone: _onDone,
        cancelOnError: false,
      );

      await _channel?.ready.timeout(
        const Duration(seconds: 4),
        onTimeout: () => _setError(
          error: 'Timeout',
          tag: 'WebsocketServiceImpl._internalConnect.ready',
        ),
      );

      _updateStatus(WsConnectionStateEnum.connected);
    } catch (e) {
      _setError(error: e, tag: 'WebsocketServiceImpl._internalConnect');
      _updateStatus(WsConnectionStateEnum.disconnected);
      _scheduleReconnect();
    }
  }

  void _setError({required Object? error, required String tag}) {
    final errorString = error?.toString();

    if (errorString != null) {
      log(errorString, error: error, name: tag);
    }

    if (_errorController.isClosed) {
      return;
    }

    _errorController.add(errorString);
  }

  void _onDone() {
    log('WebSocket connection closed.', name: 'WebsocketServiceImpl._onDone');
    _updateStatus(WsConnectionStateEnum.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;

    _updateStatus(WsConnectionStateEnum.reconnecting);

    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final delaySeconds = (_reconnectAttempts > 5) ? 5 : _reconnectAttempts * 1;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), _internalConnect);
  }

  void _onData(dynamic data) {
    try {
      final decoded = jsonDecode(data.toString());
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final rawData = BaseRawData.fromJson(decoded);
      _rawDataController.add(rawData);
    } catch (e) {
      _setError(error: e, tag: 'WebsocketServiceImpl.onData');
    }
  }

  @override
  Future<void> disconnect() async {
    _clearError();
    await _cleanupChannel();
    _updateStatus(WsConnectionStateEnum.disconnected);
  }

  Future<void> _cleanupChannel() async {
    try {
      await _channelSubscription?.cancel();
    } catch (_) {}
    _channelSubscription = null;

    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _clearError() {
    _setError(error: null, tag: '');
  }

  void _updateStatus(WsConnectionStateEnum newState) {
    if (_currentState == newState || _connectionStateController.isClosed) {
      return;
    }

    _currentState = newState;
    _connectionStateController.add(newState);

    if (newState.isConnected) {
      _clearError();
      _reconnectAttempts = 0;
    }
  }

  @override
  Stream<WsConnectionStateEnum> get connectionStateStream =>
      _connectionStateController.stream;
  @override
  Stream<BaseRawData> get rawDataStream => _rawDataController.stream;
  @override
  Stream<String?> get errorStream => _errorController.stream;

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    await Future.wait([
      _connectionStateController.close(),
      _rawDataController.close(),
      _errorController.close(),
      _cleanupChannel(),
    ]);
  }
}
