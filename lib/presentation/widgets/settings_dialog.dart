import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/websocket_repository_impl.dart';
import '../../logic/production/production_cubit.dart';
import '../../logic/settings/settings_cubit.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _urlController;
  late double _warningSec;
  late double _criticalSec;
  late bool _eggSound;
  late bool _alarmSound;
  late int _defaultBoxCapacity;
  late double _f1Min;
  late double _f2Min;
  late double _inspectionSec;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsCubit>().state;
    _urlController = TextEditingController(text: settings.wsUrl);
    _warningSec = settings.doorWarningSeconds.toDouble();
    _criticalSec = settings.doorCriticalSeconds.toDouble();
    _eggSound = settings.eggSoundEnabled;
    _alarmSound = settings.alarmSoundEnabled;
    _defaultBoxCapacity = settings.defaultBoxCapacity;
    _f1Min = settings.freezer1BaseMinutes.toDouble();
    _f2Min = settings.freezer2BaseMinutes.toDouble();
    _inspectionSec = settings.doorInspectionThresholdSeconds.toDouble();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _save() {
    final settingsCubit = context.read<SettingsCubit>();
    final productionCubit = context.read<ProductionCubit>();

    settingsCubit.updateDoorThresholds(
      warningSeconds: _warningSec.toInt(),
      criticalSeconds: _criticalSec.toInt(),
    );
    settingsCubit.toggleEggSound(_eggSound);
    settingsCubit.toggleAlarmSound(_alarmSound);
    settingsCubit.updateDefaultBoxCapacity(_defaultBoxCapacity);
    settingsCubit.updateFreezerBaseTimes(
      f1Minutes: _f1Min.toInt(),
      f2Minutes: _f2Min.toInt(),
    );
    settingsCubit.updateDoorInspectionThreshold(_inspectionSec.toInt());
    productionCubit.setBoxCapacity(_defaultBoxCapacity);

    final newUrl = _urlController.text.trim();
    if (newUrl.isNotEmpty && newUrl != settingsCubit.state.wsUrl) {
      settingsCubit.updateWsUrl(newUrl);
      try {
        context.read<IWebSocketRepository>().connect(newUrl);
      } catch (_) {}
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.surfaceBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppTheme.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Configurações do Monitoramento',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: AppTheme.surfaceElevated, height: 1),
              const SizedBox(height: 20),

              // Section 1: WebSocket Address
              const Text(
                'ENDEREÇO DO WEBSOCKET ARDUINO / ESP32',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _urlController,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'ws://192.168.0.58:81',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(
                    Icons.lan_rounded,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Section 2: Progressive Alerts Configuration
              const Text(
                'LIMITES DE ALERTA DE PORTA ABERTA',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Warning slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Alerta Amarelo (Atenção):',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${_warningSec.toInt()} segundos',
                    style: const TextStyle(
                      color: AppTheme.warningAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.warningAmber,
                  thumbColor: AppTheme.warningAmber,
                ),
                child: Slider(
                  value: _warningSec,
                  min: 5,
                  max: 120,
                  divisions: 23,
                  label: '${_warningSec.toInt()}s',
                  onChanged: (val) {
                    setState(() {
                      _warningSec = val;
                      if (_criticalSec <= _warningSec) {
                        _criticalSec = _warningSec + 10;
                      }
                    });
                  },
                ),
              ),

              // Critical slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Alerta Vermelho (Crítico + Alarme):',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${_criticalSec.toInt()} segundos',
                    style: const TextStyle(
                      color: AppTheme.dangerRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.dangerRed,
                  thumbColor: AppTheme.dangerRed,
                ),
                child: Slider(
                  value: _criticalSec,
                  min: 15,
                  max: 300,
                  divisions: 57,
                  label: '${_criticalSec.toInt()}s',
                  onChanged: (val) {
                    setState(() {
                      if (val > _warningSec) {
                        _criticalSec = val;
                      }
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Section 3: Industrial Batch & Box Configuration
              const Text(
                'LOTES E RESFRIAMENTO DOS FREEZERS',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Capacidade Padrão da Caixa:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 40, label: Text('40')),
                      ButtonSegment(value: 50, label: Text('50')),
                    ],
                    selected: {_defaultBoxCapacity},
                    onSelectionChanged: (set) {
                      setState(() => _defaultBoxCapacity = set.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tempo Base Freezer 1 (Câmara):', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  Text('${_f1Min.toInt()} min', style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Slider(
                value: _f1Min,
                min: 5,
                max: 60,
                divisions: 55,
                label: '${_f1Min.toInt()} min',
                onChanged: (val) => setState(() => _f1Min = val),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tempo Base Freezer 2 (Congelamento):', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  Text('${_f2Min.toInt()} min', style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Slider(
                value: _f2Min,
                min: 5,
                max: 60,
                divisions: 55,
                label: '${_f2Min.toInt()} min',
                onChanged: (val) => setState(() => _f2Min = val),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Limiar de Inspeção Rápida de Porta:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  Text('${_inspectionSec.toInt()} s', style: const TextStyle(color: AppTheme.warningAmber, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Slider(
                value: _inspectionSec,
                min: 5,
                max: 45,
                divisions: 8,
                label: '${_inspectionSec.toInt()} s',
                onChanged: (val) => setState(() => _inspectionSec = val),
              ),

              const SizedBox(height: 16),

              // Section 4: Audio Switches
              const Text(
                'FEEDBACK SONORO E ALARMES',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppTheme.eggOrange,
                title: const Text(
                  'Som ao detectar passagem de ovo (Hit)',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                ),
                value: _eggSound,
                onChanged: (val) => setState(() => _eggSound = val),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppTheme.dangerRed,
                title: const Text(
                  'Alarme sonoro ao atingir tempo crítico de porta',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                ),
                value: _alarmSound,
                onChanged: (val) => setState(() => _alarmSound = val),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: AppTheme.background,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text(
                      'Salvar e Aplicar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
