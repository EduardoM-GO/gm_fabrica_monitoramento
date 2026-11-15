import 'package:material_ui/material_ui.dart';
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

        return AlertDialog(
          backgroundColor: colorScheme.surfaceContainerHigh,
          title: Row(
            children: [
              Icon(Icons.settings_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Configurações do Kiosk & ESP32',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Atual do WebSocket
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status Hardware: ${_statusLabel(state)}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: isDiscovering
                              ? null
                              : () async {
                                  final found = await vm
                                      .discoverEsp32OnNetwork();
                                  if (found && mounted) {
                                    _hostController.text = vm.espHost.value;
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
                              : const Icon(Icons.radar_rounded, size: 16),
                          label: Text(
                            isDiscovering
                                ? 'Buscando...'
                                : 'Auto-Descobrir ESP32',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // IP e Porta
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _hostController,
                          decoration: const InputDecoration(
                            labelText: 'IP / Host do ESP32',
                            hintText: '192.168.0.58 ou esp32.local',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
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

                  const SizedBox(height: 12),
                  const Divider(),

                  // Controles de Áudio
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'Som de Contagem de Ovos (Bip + Caixa)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: eggSound,
                    onChanged: vm.toggleEggSound,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'Alarmes Sonoros de Freezer (Pronto / Porta Aberta)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: alarmSound,
                    onChanged: vm.toggleAlarmSound,
                  ),

                  if (widget.freezerViewModel != null) ...[
                    const Divider(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          await widget.freezerViewModel!.resetCalibration('f1');
                          await widget.freezerViewModel!.resetCalibration('f2');
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

  String _statusLabel(WsConnectionStateEnum state) => switch (state) {
    WsConnectionStateEnum.connected => 'Conectado (Online)',
    WsConnectionStateEnum.connecting => 'Conectando...',
    WsConnectionStateEnum.reconnecting => 'Reconectando...',
    WsConnectionStateEnum.disconnected => 'Desconectado (Offline)',
  };
}

