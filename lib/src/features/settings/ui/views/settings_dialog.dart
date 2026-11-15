import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/status_badge.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/enum/ws_connection_state_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/ui/view_models/freezer_monitoring_view_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/settings/ui/view_models/settings_view_model.dart';
import 'package:signals/signals_flutter.dart';

final class SettingsDialog extends StatefulWidget {
  final SettingsViewModel settingsViewModel;
  final FreezerMonitoringViewModel? freezerViewModel;

  const SettingsDialog({
    super.key,
    required this.settingsViewModel,
    this.freezerViewModel,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(
      text: widget.settingsViewModel.espHost.value,
    );
    _portController = TextEditingController(
      text: widget.settingsViewModel.espPort.value.toString(),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vm = widget.settingsViewModel;

    return SignalBuilder(
      builder: (context) {
        final state = vm.connectionState.value;
        final isDiscovering = vm.isDiscovering.value;
        final eggSound = vm.eggSoundEnabled.value;
        final alarmSound = vm.alarmSoundEnabled.value;

        final (Color statusColor, String statusText) = switch (state) {
          WsConnectionStateEnum.connected => (
            AppTheme.successGreen,
            'Conectado (Online)',
          ),
          WsConnectionStateEnum.connecting => (
            AppTheme.warningAmber,
            'Conectando...',
          ),
          WsConnectionStateEnum.reconnecting => (
            AppTheme.warningAmber,
            'Reconectando...',
          ),
          WsConnectionStateEnum.disconnected => (
            AppTheme.dangerRed,
            'Desconectado (Offline)',
          ),
        };

        return AlertDialog(
          backgroundColor: colorScheme.surfaceContainerHigh,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: AppSpacing.borderRadiusXs,
                ),
                child: Icon(
                  Icons.settings_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Configurações do Kiosk & ESP32',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: AppTheme.fontHeading,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Card Tonal: Status e Auto-Discovery do Hardware ---
                  Card.filled(
                    color: colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: StatusBadge(
                                  label: statusText,
                                  color: statusColor,
                                  showDot: true,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: FilledButton.tonalIcon(
                                    onPressed: isDiscovering
                                        ? null
                                        : () async {
                                            final found = await vm
                                                .discoverEsp32OnNetwork();
                                            if (found && mounted) {
                                              _hostController.text =
                                                  vm.espHost.value;
                                            }
                                          },
                                    icon: isDiscovering
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.radar_rounded,
                                            size: 16,
                                          ),
                                    label: Text(
                                      isDiscovering
                                          ? 'Buscando...'
                                          : 'Auto-Descobrir ESP32',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _hostController,
                                  style: const TextStyle(
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'IP / Host do ESP32',
                                    hintText: '192.168.0.58 ou esp32.local',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: _portController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Porta',
                                    hintText: '81',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // --- Card Tonal: Feedback Sonoro Industrial ---
                  Card.filled(
                    color: colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text(
                              'Som de Contagem de Ovos (Bip + Caixa)',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            value: eggSound,
                            onChanged: vm.toggleEggSound,
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text(
                              'Alarmes Sonoros de Freezer (Pronto / Porta Aberta)',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            value: alarmSound,
                            onChanged: vm.toggleAlarmSound,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (widget.freezerViewModel != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: TextButton.icon(
                          onPressed: () async {
                            await widget.freezerViewModel!.resetCalibration(
                              'f1',
                            );
                            await widget.freezerViewModel!.resetCalibration(
                              'f2',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Calibração adaptativa dos freezers restaurada para o padrão.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.restore_rounded, size: 18),
                          label: const Text(
                            'Resetar Calibração Adaptativa dos Freezers',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final host = _hostController.text.trim();
                final port = int.tryParse(_portController.text.trim()) ?? 81;
                await vm.updateEndpointAndConnect(host, port);
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Salvar e Conectar'),
            ),
          ],
        );
      },
    );
  }
}
