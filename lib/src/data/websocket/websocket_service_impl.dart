import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:gm_fabrica_monitoramento/src/data/websocket/enum/ws_connection_state_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/esp32_discovery_service.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/websocket_service.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final class WebsocketServiceImpl implements WebsocketService {
  /// Timeout curto para conexão em rede local (LAN Wi-Fi)
  static const Duration _lanConnectTimeout = Duration(milliseconds: 850);

  /// Intervalo de ping WebSocket na LAN para detectar desconexão física rapidamente
  static const Duration _lanPingInterval = Duration(milliseconds: 1500);

  /// Watchdog de silêncio: se não chegar telemetria/frames em 3.5s, considera desconectado
  static const Duration _lanSilenceWatchdog = Duration(milliseconds: 3500);

  final Esp32DiscoveryService _discoveryService;
  final void Function(String discoveredHost, int port)? onHostDiscovered;

  final _connectionStateController =
      StreamController<WsConnectionStateEnum>.broadcast();
  final _rawDataController = StreamController<BaseRawData>.broadcast();
  final _errorController = StreamController<String?>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _reconnectTimer;
  Timer? _watchdogTimer;

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
      _channel = IOWebSocketChannel.connect(
        Uri.parse(_url),
        connectTimeout: _lanConnectTimeout,
        pingInterval: _lanPingInterval,
      );

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
        _lanConnectTimeout,
        onTimeout: () => throw TimeoutException('WebSocket LAN connection timeout'),
      );

      _updateStatus(WsConnectionStateEnum.connected);
      _resetWatchdog();
    } catch (e) {
      _setError(error: e, tag: 'WebsocketServiceImpl._internalConnect');
      _updateStatus(WsConnectionStateEnum.disconnected);
      _scheduleReconnect();
    }
  }

  /// Reinicia o watchdog de inatividade da LAN: se o ESP32 for desligado ou perder Wi-Fi
  /// sem enviar pacote FIN, detecta a queda em 3.5s e já reconecta/descobre.
  void _resetWatchdog() {
    _watchdogTimer?.cancel();
    if (_isDisposed || !_currentState.isConnected) return;

    _watchdogTimer = Timer(_lanSilenceWatchdog, () {
      if (_isDisposed || !_currentState.isConnected) return;
      log(
        'LAN watchdog timeout: sem telemetria do ESP32 por ${_lanSilenceWatchdog.inMilliseconds}ms.',
        name: 'WebsocketServiceImpl._resetWatchdog',
      );
      _cleanupChannel();
      _updateStatus(WsConnectionStateEnum.disconnected);
      _scheduleReconnect();
    });
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
    _watchdogTimer?.cancel();
    _updateStatus(WsConnectionStateEnum.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;

    _watchdogTimer?.cancel();
    _updateStatus(WsConnectionStateEnum.reconnecting);

    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    // Na mesma rede local (LAN), já dispara Auto-Discovery logo na 1ª falha (e a cada 2 tentativas)
    if ((_reconnectAttempts == 1 || _reconnectAttempts % 2 == 0) &&
        !_isDiscovering) {
      _tryAutoDiscovery();
    }

    // Backoff curto de LAN: 500ms na 1ª tentativa, máximo de 1200ms nas seguintes
    final delayMs = _reconnectAttempts == 1
        ? 500
        : (_reconnectAttempts == 2 ? 800 : 1200);
    _reconnectTimer = Timer(
      Duration(milliseconds: delayMs),
      _internalConnect,
    );
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
        // Reconecta imediatamente ao novo IP encontrado na LAN
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(
          const Duration(milliseconds: 50),
          _internalConnect,
        );
      }
    } finally {
      _isDiscovering = false;
    }
  }

  void _onData(dynamic data) {
    _resetWatchdog();
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
    _watchdogTimer?.cancel();
    _clearError();
    await _cleanupChannel();
    _updateStatus(WsConnectionStateEnum.disconnected);
  }

  Future<void> _cleanupChannel() async {
    _watchdogTimer?.cancel();
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
    _watchdogTimer?.cancel();
    await Future.wait([
      _connectionStateController.close(),
      _rawDataController.close(),
      _errorController.close(),
      _cleanupChannel(),
    ]);
  }
}
