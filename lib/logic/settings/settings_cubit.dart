import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  static const _keyWsUrl = 'settings_ws_url';
  static const _keyWarningSec = 'settings_warning_sec';
  static const _keyCriticalSec = 'settings_critical_sec';
  static const _keyEggSound = 'settings_egg_sound';
  static const _keyAlarmSound = 'settings_alarm_sound';
  static const _keyMockEnabled = 'settings_mock_enabled';
  static const _keyBoxCapacity = 'settings_box_capacity';
  static const _keyF1BaseMin = 'settings_f1_base_min';
  static const _keyF2BaseMin = 'settings_f2_base_min';
  static const _keyInspectionSec = 'settings_inspection_sec';

  SettingsCubit() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wsUrl = prefs.getString(_keyWsUrl) ?? state.wsUrl;
      final warningSec = prefs.getInt(_keyWarningSec) ?? state.doorWarningSeconds;
      final criticalSec = prefs.getInt(_keyCriticalSec) ?? state.doorCriticalSeconds;
      final eggSound = prefs.getBool(_keyEggSound) ?? state.eggSoundEnabled;
      final alarmSound = prefs.getBool(_keyAlarmSound) ?? state.alarmSoundEnabled;
      final mock = prefs.getBool(_keyMockEnabled) ?? state.isMockEnabled;
      final boxCapacity = prefs.getInt(_keyBoxCapacity) ?? state.defaultBoxCapacity;
      final f1Min = prefs.getInt(_keyF1BaseMin) ?? state.freezer1BaseMinutes;
      final f2Min = prefs.getInt(_keyF2BaseMin) ?? state.freezer2BaseMinutes;
      final inspectionSec = prefs.getInt(_keyInspectionSec) ?? state.doorInspectionThresholdSeconds;

      emit(state.copyWith(
        wsUrl: wsUrl,
        doorWarningSeconds: warningSec,
        doorCriticalSeconds: criticalSec,
        eggSoundEnabled: eggSound,
        alarmSoundEnabled: alarmSound,
        isMockEnabled: mock,
        defaultBoxCapacity: boxCapacity,
        freezer1BaseMinutes: f1Min,
        freezer2BaseMinutes: f2Min,
        doorInspectionThresholdSeconds: inspectionSec,
      ));
    } catch (_) {
      // Fallback to default state if SharedPreferences fails or is in mock mode
    }
  }

  Future<void> updateWsUrl(String url) async {
    final clean = url.trim();
    emit(state.copyWith(wsUrl: clean));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWsUrl, clean);
  }

  Future<void> updateDoorThresholds({int? warningSeconds, int? criticalSeconds}) async {
    final newWarning = warningSeconds ?? state.doorWarningSeconds;
    final newCritical = criticalSeconds ?? state.doorCriticalSeconds;
    emit(state.copyWith(
      doorWarningSeconds: newWarning,
      doorCriticalSeconds: newCritical,
    ));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWarningSec, newWarning);
    await prefs.setInt(_keyCriticalSec, newCritical);
  }

  Future<void> toggleEggSound(bool enabled) async {
    emit(state.copyWith(eggSoundEnabled: enabled));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEggSound, enabled);
  }

  Future<void> toggleAlarmSound(bool enabled) async {
    emit(state.copyWith(alarmSoundEnabled: enabled));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAlarmSound, enabled);
  }

  Future<void> toggleMock(bool enabled) async {
    emit(state.copyWith(isMockEnabled: enabled));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMockEnabled, enabled);
  }

  Future<void> updateDefaultBoxCapacity(int capacity) async {
    emit(state.copyWith(defaultBoxCapacity: capacity));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBoxCapacity, capacity);
  }

  Future<void> updateFreezerBaseTimes({int? f1Minutes, int? f2Minutes}) async {
    final newF1 = f1Minutes ?? state.freezer1BaseMinutes;
    final newF2 = f2Minutes ?? state.freezer2BaseMinutes;
    emit(state.copyWith(
      freezer1BaseMinutes: newF1,
      freezer2BaseMinutes: newF2,
    ));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyF1BaseMin, newF1);
    await prefs.setInt(_keyF2BaseMin, newF2);
  }

  Future<void> updateDoorInspectionThreshold(int seconds) async {
    emit(state.copyWith(doorInspectionThresholdSeconds: seconds));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyInspectionSec, seconds);
  }
}

