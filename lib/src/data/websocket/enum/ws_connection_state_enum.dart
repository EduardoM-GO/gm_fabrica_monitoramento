enum WsConnectionStateEnum {
  disconnected,
  connecting,
  connected,
  reconnecting;

  bool get isNotDisconnected => this != disconnected;
  bool get isConnected => this == connected;
}
