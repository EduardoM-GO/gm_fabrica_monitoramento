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
  static const _keyEggHitSound = 'egg_hit_sound_enabled';
  static const _keyBoxCompletedSound = 'box_completed_sound_enabled';
  static const _keyConveyorAlertSound = 'conveyor_alert_sound_enabled';
  static const _keyFreezerStartSound = 'freezer_start_sound_enabled';
  static const _keyFreezerReadySound = 'freezer_ready_sound_enabled';
  static const _keyDoorToggleSound = 'door_toggle_sound_enabled';
  static const _keyDoorAlarmSound = 'door_alarm_sound_enabled';

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

  // Chaves individuais de som para os 3 operadores na sala 4x4m
  late final Signal<bool> eggHitSoundEnabled;
  late final Signal<bool> boxCompletedSoundEnabled;
  late final Signal<bool> conveyorAlertSoundEnabled;
  late final Signal<bool> freezerStartSoundEnabled;
  late final Signal<bool> freezerReadySoundEnabled;
  late final Signal<bool> doorToggleSoundEnabled;
  late final Signal<bool> doorAlarmSoundEnabled;

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

    eggHitSoundEnabled = signal<bool>(audioService?.eggHitSoundEnabled ?? true);
    boxCompletedSoundEnabled = signal<bool>(
      audioService?.boxCompletedSoundEnabled ?? true,
    );
    conveyorAlertSoundEnabled = signal<bool>(
      audioService?.conveyorAlertSoundEnabled ?? true,
    );
    freezerStartSoundEnabled = signal<bool>(
      audioService?.freezerStartSoundEnabled ?? true,
    );
    freezerReadySoundEnabled = signal<bool>(
      audioService?.freezerReadySoundEnabled ?? true,
    );
    doorToggleSoundEnabled = signal<bool>(
      audioService?.doorToggleSoundEnabled ?? true,
    );
    doorAlarmSoundEnabled = signal<bool>(
      audioService?.doorAlarmSoundEnabled ?? true,
    );

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

      final sEggHit = prefs.getBool(_keyEggHitSound);
      if (sEggHit != null) {
        eggHitSoundEnabled.value = sEggHit;
        _audioService?.eggHitSoundEnabled = sEggHit;
      }
      final sBox = prefs.getBool(_keyBoxCompletedSound);
      if (sBox != null) {
        boxCompletedSoundEnabled.value = sBox;
        _audioService?.boxCompletedSoundEnabled = sBox;
      }
      final sConveyor = prefs.getBool(_keyConveyorAlertSound);
      if (sConveyor != null) {
        conveyorAlertSoundEnabled.value = sConveyor;
        _audioService?.conveyorAlertSoundEnabled = sConveyor;
      }
      final sFStart = prefs.getBool(_keyFreezerStartSound);
      if (sFStart != null) {
        freezerStartSoundEnabled.value = sFStart;
        _audioService?.freezerStartSoundEnabled = sFStart;
      }
      final sFReady = prefs.getBool(_keyFreezerReadySound);
      if (sFReady != null) {
        freezerReadySoundEnabled.value = sFReady;
        _audioService?.freezerReadySoundEnabled = sFReady;
      }
      final sDoorToggle = prefs.getBool(_keyDoorToggleSound);
      if (sDoorToggle != null) {
        doorToggleSoundEnabled.value = sDoorToggle;
        _audioService?.doorToggleSoundEnabled = sDoorToggle;
      }
      final sDoorAlarm = prefs.getBool(_keyDoorAlarmSound);
      if (sDoorAlarm != null) {
        doorAlarmSoundEnabled.value = sDoorAlarm;
        _audioService?.doorAlarmSoundEnabled = sDoorAlarm;
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
    eggHitSoundEnabled.value = enabled;
    boxCompletedSoundEnabled.value = enabled;
    conveyorAlertSoundEnabled.value = enabled;
    _audioService?.eggSoundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEggSound, enabled);
      await prefs.setBool(_keyEggHitSound, enabled);
      await prefs.setBool(_keyBoxCompletedSound, enabled);
      await prefs.setBool(_keyConveyorAlertSound, enabled);
    } catch (_) {}
  }

  Future<void> toggleAlarmSound(bool enabled) async {
    alarmSoundEnabled.value = enabled;
    freezerStartSoundEnabled.value = enabled;
    freezerReadySoundEnabled.value = enabled;
    doorToggleSoundEnabled.value = enabled;
    doorAlarmSoundEnabled.value = enabled;
    _audioService?.alarmSoundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAlarmSound, enabled);
      await prefs.setBool(_keyFreezerStartSound, enabled);
      await prefs.setBool(_keyFreezerReadySound, enabled);
      await prefs.setBool(_keyDoorToggleSound, enabled);
      await prefs.setBool(_keyDoorAlarmSound, enabled);
    } catch (_) {}
  }

  Future<void> toggleEggHitSound(bool enabled) async {
    eggHitSoundEnabled.value = enabled;
    _audioService?.eggHitSoundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEggHitSound, enabled);
    } catch (_) {}
  }

  Future<void> toggleBoxCompletedSound(bool enabled) async {
    boxCompletedSoundEnabled.value = enabled;
    _audioService?.boxCompletedSoundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBoxCompletedSound, enabled);
    } catch (_) {}
  }

  Future<void> toggleConveyorAlertSound(bool enabled) async {
    conveyorAlertSoundEnabled.value = enabled;
    _audioService?.conveyorAlertSoundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyConveyorAlertSound, enabled);
    } catch (_) {}
  }

  Future<void> toggleFreezerStartSound(bool enabled) async {
    freezerStartSoundEnabled.value = enabled;
    _audioService?.freezerStartSoundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyFreezerStartSound, enabled);
    } catch (_) {}
  }

  Future<void> toggleFreezerReadySound(bool enabled) async {
    freezerReadySoundEnabled.value = enabled;
    _audioService?.freezerReadySoundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyFreezerReadySound, enabled);
    } catch (_) {}
  }

  Future<void> toggleDoorToggleSound(bool enabled) async {
    doorToggleSoundEnabled.value = enabled;
    _audioService?.doorToggleSoundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDoorToggleSound, enabled);
    } catch (_) {}
  }

  Future<void> toggleDoorAlarmSound(bool enabled) async {
    doorAlarmSoundEnabled.value = enabled;
    _audioService?.doorAlarmSoundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDoorAlarmSound, enabled);
    } catch (_) {}
  }

  // --- Métodos de Teste Sonoro ("Ouvir/Testar") nas Configurações ---
  void testEggHitSound() => _audioService?.playEggHit(forceTest: true);
  void testBoxCompletedSound() =>
      _audioService?.playBoxCompleted(forceTest: true);
  void testConveyorAlertSound() =>
      _audioService?.playConveyorAlert(forceTest: true);
  void testFreezerStartSound(String freezerId) =>
      _audioService?.playFreezerStarted(freezerId: freezerId, forceTest: true);
  void testFreezerReadySound(String freezerId) =>
      _audioService?.playFreezerReady(freezerId: freezerId, forceTest: true);
  void testDoorToggleSound() => _audioService?.playDoorOpened(forceTest: true);
  void testDoorAlarmSound() => _audioService?.playDoorAlarm(forceTest: true);

  void dispose() {
    _connSub?.cancel();
    _errSub?.cancel();
  }
}

