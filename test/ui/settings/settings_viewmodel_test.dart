import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/src/ui/settings/view_models/settings_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsViewModel MVVM Tests', () {
    test('Loads initial state and applies defaults', () {
      final viewModel = SettingsViewModel();

      expect(viewModel.wsUrl, equals('ws://192.168.0.58:81'));
      expect(viewModel.doorWarningSeconds, equals(30));
      expect(viewModel.doorCriticalSeconds, equals(60));
      expect(viewModel.eggSoundEnabled, isTrue);
      expect(viewModel.alarmSoundEnabled, isTrue);
      expect(viewModel.isMockEnabled, isFalse);
      expect(viewModel.defaultBoxCapacity, equals(50));
      expect(viewModel.freezer1BaseMinutes, equals(20));
      expect(viewModel.freezer2BaseMinutes, equals(15));
    });

    test('updateWsUrl persists and notifies listeners', () async {
      final viewModel = SettingsViewModel();
      int notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      await viewModel.updateWsUrl('ws://10.0.0.99:8080');

      expect(viewModel.wsUrl, equals('ws://10.0.0.99:8080'));
      expect(notifyCount, greaterThan(0));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('settings_ws_url'), equals('ws://10.0.0.99:8080'));
    });

    test('updateDoorThresholds updates warning and critical seconds', () async {
      final viewModel = SettingsViewModel();

      await viewModel.updateDoorThresholds(
        warningSeconds: 45,
        criticalSeconds: 90,
      );

      expect(viewModel.doorWarningSeconds, equals(45));
      expect(viewModel.doorCriticalSeconds, equals(90));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('settings_warning_sec'), equals(45));
      expect(prefs.getInt('settings_critical_sec'), equals(90));
    });

    test('toggleEggSound and toggleAlarmSound updates values', () async {
      final viewModel = SettingsViewModel();

      await viewModel.toggleEggSound(false);
      expect(viewModel.eggSoundEnabled, isFalse);

      await viewModel.toggleAlarmSound(false);
      expect(viewModel.alarmSoundEnabled, isFalse);
    });

    test('saveSettingsCommand persists new settings batch', () async {
      final viewModel = SettingsViewModel();

      final newSettings = viewModel.state.copyWith(
        wsUrl: 'ws://custom:81',
        defaultBoxCapacity: 40,
        freezer1BaseMinutes: 25,
      );

      await viewModel.saveSettingsCommand.execute(newSettings);

      expect(viewModel.saveSettingsCommand.completed, isTrue);
      expect(viewModel.wsUrl, equals('ws://custom:81'));
      expect(viewModel.defaultBoxCapacity, equals(40));
      expect(viewModel.freezer1BaseMinutes, equals(25));
    });

    test('resetToDefaultsCommand resets state and clears prefs', () async {
      final viewModel = SettingsViewModel();

      await viewModel.updateWsUrl('ws://modified:81');
      expect(viewModel.wsUrl, equals('ws://modified:81'));

      await viewModel.resetToDefaultsCommand.execute();
      expect(viewModel.resetToDefaultsCommand.completed, isTrue);
      expect(viewModel.wsUrl, equals('ws://192.168.0.58:81'));
    });
  });
}
