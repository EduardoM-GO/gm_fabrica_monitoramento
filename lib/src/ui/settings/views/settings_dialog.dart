import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/repositories/websocket_repository.dart';
import '../../../core/themes/app_theme.dart';
import '../../production/view_models/production_viewmodel.dart';
import '../view_models/settings_viewmodel.dart';

/// Modal dialog for configuring WebSocket endpoints, alarm thresholds, and capacities.
/// Follows Material 3 styling and the official Flutter MVVM UI architecture.
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
    final settings = context.read<SettingsViewModel>().state;
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
    final settingsViewModel = context.read<SettingsViewModel>();
    final productionViewModel = context.read<ProductionViewModel>();

    final updatedState = settingsViewModel.state.copyWith(
      wsUrl: _urlController.text.trim(),
      doorWarningSeconds: _warningSec.toInt(),
      doorCriticalSeconds: _criticalSec.toInt(),
      eggSoundEnabled: _eggSound,
      alarmSoundEnabled: _alarmSound,
      defaultBoxCapacity: _defaultBoxCapacity,
      freezer1BaseMinutes: _f1Min.toInt(),
      freezer2BaseMinutes: _f2Min.toInt(),
      doorInspectionThresholdSeconds: _inspectionSec.toInt(),
    );

    settingsViewModel.saveSettingsCommand.execute(updatedState);
    productionViewModel.setBoxCapacity(_defaultBoxCapacity);

    final newUrl = _urlController.text.trim();
    if (newUrl.isNotEmpty && newUrl != settingsViewModel.state.wsUrl) {
      try {
        context.read<IWebSocketRepository>().connect(newUrl);
      } catch (_) {}
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
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
              Divider(color: colorScheme.outlineVariant, height: 1),
              const SizedBox(height: 20),

              // Section: Hardware / WebSocket
              const Text(
                'HARDWARE / ESP32',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _urlController,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: 'Endereço WebSocket do ESP32',
                  labelStyle: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                  hintText: 'ws://192.168.0.58:81',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  prefixIcon: const Icon(
                    Icons.lan_rounded,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryBlue,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Section: Production Box Capacity
              const Text(
                'CAPACIDADE PADRÃO DA CAIXA',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text(
                          '50 Ovos (Padrão)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      selected: _defaultBoxCapacity == 50,
                      onSelected: (val) {
                        if (val) setState(() => _defaultBoxCapacity = 50);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text(
                          '40 Ovos (Ovos Grandes)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      selected: _defaultBoxCapacity == 40,
                      onSelected: (val) {
                        if (val) setState(() => _defaultBoxCapacity = 40);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Section: Freezers Timing
              const Text(
                'TEMPOS BASE DE RESFRIAMENTO',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Freezer 1 (Câmara Resfriamento):',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  ),
                  Text(
                    '${_f1Min.toInt()} min',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _f1Min,
                min: 5,
                max: 45,
                divisions: 40,
                activeColor: AppTheme.primaryBlue,
                onChanged: (val) => setState(() => _f1Min = val),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Freezer 2 (Congelamento):',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  ),
                  Text(
                    '${_f2Min.toInt()} min',
                    style: const TextStyle(
                      color: Color(0xFF67E8F9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _f2Min,
                min: 5,
                max: 45,
                divisions: 40,
                activeColor: const Color(0xFF67E8F9),
                onChanged: (val) => setState(() => _f2Min = val),
              ),

              const SizedBox(height: 20),

              // Section: Door Alerts
              const Text(
                'ALERTAS DE PORTA ABERTA',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Aviso visual (âmbar):',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  ),
                  Text(
                    '${_warningSec.toInt()}s',
                    style: const TextStyle(
                      color: AppTheme.warningAmber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _warningSec,
                min: 10,
                max: 120,
                divisions: 22,
                activeColor: AppTheme.warningAmber,
                onChanged: (val) {
                  setState(() {
                    _warningSec = val;
                    if (_criticalSec <= _warningSec) {
                      _criticalSec = _warningSec + 10;
                    }
                  });
                },
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Alarme sonoro crítico (vermelho):',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  ),
                  Text(
                    '${_criticalSec.toInt()}s',
                    style: const TextStyle(
                      color: AppTheme.dangerRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _criticalSec,
                min: 15,
                max: 300,
                divisions: 57,
                activeColor: AppTheme.dangerRed,
                onChanged: (val) {
                  setState(() {
                    _criticalSec = val;
                    if (_criticalSec <= _warningSec) {
                      _warningSec = _criticalSec - 5;
                    }
                  });
                },
              ),

              const SizedBox(height: 20),

              // Section: Audio
              const Text(
                'FEEDBACK SONORO',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text(
                  'Som a cada ovo embalado',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                ),
                subtitle: const Text(
                  'Bipe suave a cada passagem pelo sensor',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                value: _eggSound,
                activeThumbColor: AppTheme.eggOrange,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _eggSound = val),
              ),
              SwitchListTile(
                title: const Text(
                  'Sirene de porta aberta',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                ),
                subtitle: const Text(
                  'Alerta sonoro ao atingir o tempo crítico',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                value: _alarmSound,
                activeThumbColor: AppTheme.dangerRed,
                contentPadding: EdgeInsets.zero,
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
