abstract class WebSocketRepository {
  Stream<HitFrame> get hitStream;
  Stream<TelemetryFrame> get telemetryStream;
  Stream<ConnectionStatus> get connectionStatusStream;
  Stream<String?> get errorStream;
  ConnectionStatus get currentStatus;

  void connect(String url);
  void disconnect();
  void dispose();

  // Simulação / Teste em bancada
  void toggleSimulatorDoor(int freezerNum);
  void toggleSimulatorProbe(int freezerNum);
  void simulateEggHit();
}
