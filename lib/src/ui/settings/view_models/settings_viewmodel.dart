import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/command.dart';
import '../../../utils/result.dart';
import 'settings_state.dart';

export 'settings_state.dart';

/// ViewModel managing user and factory configuration settings.
/// Implements the official Flutter MVVM architecture pattern.
class SettingsViewModel extends ChangeNotifier {
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

  SettingsState _state;
  SettingsState get state => _state;

  late final Command1<void, SettingsState> saveSettingsCommand;
  late final Command0<void> resetToDefaultsCommand;

  // Convenient property getters for Views
  String get wsUrl => _state.wsUrl;
  int get doorWarningSeconds => _state.doorWarningSeconds;
  int get doorCriticalSeconds => _state.doorCriticalSeconds;
  bool get eggSoundEnabled => _state.eggSoundEnabled;
  bool get alarmSoundEnabled => _state.alarmSoundEnabled;
  bool get isMockEnabled => _state.isMockEnabled;
  int get defaultBoxCapacity => _state.defaultBoxCapacity;
  int get freezer1BaseMinutes => _state.freezer1BaseMinutes;
  int get freezer2BaseMinutes => _state.freezer2BaseMinutes;
  int get doorInspectionThresholdSeconds =>
      _state.doorInspectionThresholdSeconds;

  SettingsViewModel({SettingsState initialState = const SettingsState()})
    : _state = initialState {
    saveSettingsCommand = Command1(_saveSettings);
    resetToDefaultsCommand = Command0(_resetToDefaults);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wsUrl = prefs.getString(_keyWsUrl) ?? _state.wsUrl;
      final warningSec =
          prefs.getInt(_keyWarningSec) ?? _state.doorWarningSeconds;
      final criticalSec =
          prefs.getInt(_keyCriticalSec) ?? _state.doorCriticalSeconds;
      final eggSound = prefs.getBool(_keyEggSound) ?? _state.eggSoundEnabled;
      final alarmSound =
          prefs.getBool(_keyAlarmSound) ?? _state.alarmSoundEnabled;
      final mock = prefs.getBool(_keyMockEnabled) ?? _state.isMockEnabled;
      final boxCapacity =
          prefs.getInt(_keyBoxCapacity) ?? _state.defaultBoxCapacity;
      final f1Min = prefs.getInt(_keyF1BaseMin) ?? _state.freezer1BaseMinutes;
      final f2Min = prefs.getInt(_keyF2BaseMin) ?? _state.freezer2BaseMinutes;
      final inspectionSec =
          prefs.getInt(_keyInspectionSec) ??
          _state.doorInspectionThresholdSeconds;

      _state = _state.copyWith(
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
      );
      notifyListeners();
    } catch (_) {
      // SharedPreferences failure fallback to current state
    }
  }

  Future<Result<void>> _saveSettings(SettingsState newSettings) async {
    try {
      _state = newSettings;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyWsUrl, newSettings.wsUrl);
      await prefs.setInt(_keyWarningSec, newSettings.doorWarningSeconds);
      await prefs.setInt(_keyCriticalSec, newSettings.doorCriticalSeconds);
      await prefs.setBool(_keyEggSound, newSettings.eggSoundEnabled);
      await prefs.setBool(_keyAlarmSound, newSettings.alarmSoundEnabled);
      await prefs.setBool(_keyMockEnabled, newSettings.isMockEnabled);
      await prefs.setInt(_keyBoxCapacity, newSettings.defaultBoxCapacity);
      await prefs.setInt(_keyF1BaseMin, newSettings.freezer1BaseMinutes);
      await prefs.setInt(_keyF2BaseMin, newSettings.freezer2BaseMinutes);
      await prefs.setInt(
        _keyInspectionSec,
        newSettings.doorInspectionThresholdSeconds,
      );
      return const Result.ok(null);
    } catch (e) {
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void>> _resetToDefaults() async {
    try {
      _state = const SettingsState();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return const Result.ok(null);
    } catch (e) {
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<void> updateWsUrl(String url) async {
    final clean = url.trim();
    _state = _state.copyWith(wsUrl: clean);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyWsUrl, clean);
    } catch (_) {}
  }

  Future<void> updateDoorThresholds({
    int? warningSeconds,
    int? criticalSeconds,
  }) async {
    final newWarning = warningSeconds ?? _state.doorWarningSeconds;
    final newCritical = criticalSeconds ?? _state.doorCriticalSeconds;
    _state = _state.copyWith(
      doorWarningSeconds: newWarning,
      doorCriticalSeconds: newCritical,
    );
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyWarningSec, newWarning);
      await prefs.setInt(_keyCriticalSec, newCritical);
    } catch (_) {}
  }

  Future<void> toggleEggSound(bool enabled) async {
    _state = _state.copyWith(eggSoundEnabled: enabled);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEggSound, enabled);
    } catch (_) {}
  }

  Future<void> toggleAlarmSound(bool enabled) async {
    _state = _state.copyWith(alarmSoundEnabled: enabled);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAlarmSound, enabled);
    } catch (_) {}
  }

  Future<void> toggleMock(bool enabled) async {
    _state = _state.copyWith(isMockEnabled: enabled);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyMockEnabled, enabled);
    } catch (_) {}
  }

  Future<void> updateDefaultBoxCapacity(int capacity) async {
    if (capacity <= 0) return;
    _state = _state.copyWith(defaultBoxCapacity: capacity);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyBoxCapacity, capacity);
    } catch (_) {}
  }

  Future<void> updateFreezerBaseTimes({int? f1Minutes, int? f2Minutes}) async {
    _state = _state.copyWith(
      freezer1BaseMinutes: f1Minutes ?? _state.freezer1BaseMinutes,
      freezer2BaseMinutes: f2Minutes ?? _state.freezer2BaseMinutes,
    );
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (f1Minutes != null) await prefs.setInt(_keyF1BaseMin, f1Minutes);
      if (f2Minutes != null) await prefs.setInt(_keyF2BaseMin, f2Minutes);
    } catch (_) {}
  }

  Future<void> updateDoorInspectionThreshold(int seconds) async {
    _state = _state.copyWith(doorInspectionThresholdSeconds: seconds);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyInspectionSec, seconds);
    } catch (_) {}
  }
}
