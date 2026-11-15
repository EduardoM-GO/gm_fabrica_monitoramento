import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:gm_fabrica_monitoramento/src/data/websocket/enum/ws_connection_state_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/esp32_discovery_service.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/websocket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final class WebsocketServiceImpl implements WebsocketService {
  final Esp32DiscoveryService _discoveryService;
  final void Function(String discoveredHost, int port)? onHostDiscovered;

  final _connectionStateController =
      StreamController<WsConnectionStateEnum>.broadcast();
  final _rawDataController = StreamController<BaseRawData>.broadcast();
  final _errorController = StreamController<String?>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _reconnectTimer;

  WsConnectionStateEnum _currentState = WsConnectionStateEnum.disconnected;
  bool _isDisposed = false;
  String _host = '192.168.0.58';
  int _port = 81;
  String _url = '';
  int _reconnectAttempts = 0;
  bool _isDiscovering = false;

  WebsocketServiceImpl({
    this._discoveryService = const Esp32DiscoveryService(),
    this.onHostDiscovered,
  });

  WsConnectionStateEnum get currentState => _currentState;
  String get currentHost => _host;
  int get currentPort => _port;

  @override
  Future<void> connect(String host, int port) async {
    _host = host.trim();
    _port = port;
    _url = 'ws://$_host:$_port';
    _reconnectAttempts = 0;
    await _internalConnect();
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
        onTimeout: () => throw TimeoutException('WebSocket connection timeout'),
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

    // A cada 3 falhas consecutivas, tenta descobrir automaticamente o IP do ESP32 na sub-rede
    if (_reconnectAttempts % 3 == 0 && !_isDiscovering) {
      _tryAutoDiscovery();
    }

    final delaySeconds = (_reconnectAttempts > 5) ? 5 : _reconnectAttempts * 1;
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), _internalConnect);
  }

  Future<void> _tryAutoDiscovery() async {
    if (_isDisposed || _isDiscovering) return;
    _isDiscovering = true;
    try {
      final foundHost = await _discoveryService.discoverHost(
        port: _port,
        lastKnownHost: _host,
      );
      if (foundHost != null && foundHost != _host && !_isDisposed) {
        _host = foundHost;
        _url = 'ws://$_host:$_port';
        onHostDiscovered?.call(_host, _port);
      }
    } finally {
      _isDiscovering = false;
    }
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
    _reconnectTimer?.cancel();
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
    _reconnectTimer?.cancel();
    await Future.wait([
      _connectionStateController.close(),
      _rawDataController.close(),
      _errorController.close(),
      _cleanupChannel(),
    ]);
  }
}
