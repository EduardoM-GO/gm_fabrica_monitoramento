import 'dart:async';

import 'package:gm_fabrica_monitoramento/src/data/services/audio_service.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/enum/ws_connection_state_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/esp32_discovery_service.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/websocket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';

final class SettingsViewModel {
  static const _keyHost = 'esp32_host';
  static const _keyPort = 'esp32_port';
  static const _keyEggSound = 'egg_sound_enabled';
  static const _keyAlarmSound = 'alarm_sound_enabled';

  final WebsocketService _wsService;
  final AudioService? _audioService;
  final Esp32DiscoveryService _discoveryService;

  late final Signal<String> espHost;
  late final Signal<int> espPort;
  late final Signal<WsConnectionStateEnum> connectionState;
  late final Signal<String?> lastError;
  late final Signal<bool> isDiscovering;
  late final Signal<bool> eggSoundEnabled;
  late final Signal<bool> alarmSoundEnabled;

  final int doorCriticalSeconds;
  final int doorInspectionThresholdSeconds;

  StreamSubscription? _connSub;
  StreamSubscription? _errSub;

  SettingsViewModel({
    required this._wsService,
    AudioService? audioService,
    this._discoveryService = const Esp32DiscoveryService(),
    String initialHost = '192.168.0.58',
    int initialPort = 81,
    this.doorCriticalSeconds = 30,
    this.doorInspectionThresholdSeconds = 12,
  }) : _audioService = audioService {
    espHost = signal<String>(initialHost);
    espPort = signal<int>(initialPort);
    connectionState = signal<WsConnectionStateEnum>(
      WsConnectionStateEnum.disconnected,
    );
    lastError = signal<String?>(null);
    isDiscovering = signal<bool>(false);
    eggSoundEnabled = signal<bool>(audioService?.eggSoundEnabled ?? true);
    alarmSoundEnabled = signal<bool>(audioService?.alarmSoundEnabled ?? true);

    _connSub = _wsService.connectionStateStream.listen((state) {
      connectionState.value = state;
    });
    _errSub = _wsService.errorStream.listen((err) {
      lastError.value = err;
    });
  }

  /// Carrega configurações salvas do SharedPreferences e inicia conexão com o ESP32
  Future<void> initAndConnect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHost = prefs.getString(_keyHost);
      final savedPort = prefs.getInt(_keyPort);
      final savedEggSound = prefs.getBool(_keyEggSound);
      final savedAlarmSound = prefs.getBool(_keyAlarmSound);

      if (savedHost != null && savedHost.isNotEmpty) {
        espHost.value = savedHost;
      }
      if (savedPort != null && savedPort > 0) {
        espPort.value = savedPort;
      }
      if (savedEggSound != null) {
        eggSoundEnabled.value = savedEggSound;
        _audioService?.eggSoundEnabled = savedEggSound;
      }
      if (savedAlarmSound != null) {
        alarmSoundEnabled.value = savedAlarmSound;
        _audioService?.alarmSoundEnabled = savedAlarmSound;
      }
    } catch (_) {}

    await _wsService.connect(espHost.value, espPort.value);
  }

  /// Atualiza o host quando o Auto-Discovery encontra o ESP32 em novo IP
  Future<void> onHostDiscovered(String host, int port) async {
    espHost.value = host;
    espPort.value = port;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyHost, host);
      await prefs.setInt(_keyPort, port);
    } catch (_) {}
  }

  /// Salva novo IP/Porta manualmente e reconecta
  Future<void> updateEndpointAndConnect(String host, int port) async {
    final cleanHost = host.trim();
    if (cleanHost.isEmpty || port <= 0) return;

    await onHostDiscovered(cleanHost, port);
    await _wsService.connect(cleanHost, port);
  }

  /// Dispara busca ativa do ESP32 na sub-rede Wi-Fi e conecta se encontrar
  Future<bool> discoverEsp32OnNetwork() async {
    if (isDiscovering.value) return false;
    isDiscovering.value = true;
    try {
      final foundHost = await _discoveryService.discoverHost(
        port: espPort.value,
        lastKnownHost: espHost.value,
      );
      if (foundHost != null) {
        await updateEndpointAndConnect(foundHost, espPort.value);
        return true;
      }
      return false;
    } finally {
      isDiscovering.value = false;
    }
  }

  Future<void> toggleEggSound(bool enabled) async {
    eggSoundEnabled.value = enabled;
    _audioService?.eggSoundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEggSound, enabled);
    } catch (_) {}
  }

  Future<void> toggleAlarmSound(bool enabled) async {
    alarmSoundEnabled.value = enabled;
    _audioService?.alarmSoundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAlarmSound, enabled);
    } catch (_) {}
  }

  void dispose() {
    _connSub?.cancel();
    _errSub?.cancel();
  }
}

