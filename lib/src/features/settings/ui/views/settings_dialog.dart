import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/supabase/supabase_bootstrap.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/status_badge.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/enum/ws_connection_state_enum.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/freezer_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/ui/view_models/freezer_monitoring_view_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/ui/view_models/egg_count_view_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/settings/ui/view_models/settings_view_model.dart';
import 'package:signals/signals_flutter.dart';

final class SettingsDialog extends StatefulWidget {
  final SettingsViewModel settingsViewModel;
  final FreezerMonitoringViewModel? freezerViewModel;
  final EggCountViewModel? eggViewModel;

  const SettingsDialog({
    super.key,
    required this.settingsViewModel,
    this.freezerViewModel,
    this.eggViewModel,
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

    // Sincroniza equipamentos e produtos do Supabase ao abrir configurações
    widget.freezerViewModel?.refreshEquipmentsAndBindings();
    widget.eggViewModel?.refreshProducts();
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
    final freezerVm = widget.freezerViewModel;
    final eggVm = widget.eggViewModel;

    return SignalBuilder(
      builder: (context) {
        final state = vm.connectionState.value;
        final isDiscovering = vm.isDiscovering.value;
        final eggHitSound = vm.eggHitSoundEnabled.value;
        final boxCompletedSound = vm.boxCompletedSoundEnabled.value;
        final conveyorAlertSound = vm.conveyorAlertSoundEnabled.value;
        final freezerStartSound = vm.freezerStartSoundEnabled.value;
        final freezerReadySound = vm.freezerReadySoundEnabled.value;
        final doorToggleSound = vm.doorToggleSoundEnabled.value;
        final doorAlarmSound = vm.doorAlarmSoundEnabled.value;

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

        final supabaseClient = supabaseOrNull;
        final currentUserEmail = supabaseClient?.auth.currentUser?.email;

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
                  'Configurações do Kiosk, Freezers & ESP32',
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
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- 1. Card Tonal: Vínculo Freezers (Supabase) <-> Sensores ESP32 ---
                  if (freezerVm != null) ...[
                    _FreezerSensorBindingsCard(
                      freezerViewModel: freezerVm,
                      eggViewModel: eggVm,
                      currentUserEmail: currentUserEmail,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  // --- 2. Card Tonal: Status e Auto-Discovery do Hardware ---
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

                  // --- 3. Card Tonal: Avisos Sonoros Únicos (Sala 4x4m — 3 Operadores) ---
                  Card.filled(
                    color: colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'AVISOS SONOROS DA SALA (TOQUE EM TESTAR PARA OUVIR)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _SoundSettingRow(
                            title: 'Bip de Ovo Contado',
                            value: eggHitSound,
                            onChanged: vm.toggleEggHitSound,
                            onTestPrimary: vm.testEggHitSound,
                            testPrimaryLabel: 'Testar',
                          ),
                          const Divider(height: 1),
                          _SoundSettingRow(
                            title: 'Caixa Fechada (Completa)',
                            value: boxCompletedSound,
                            onChanged: vm.toggleBoxCompletedSound,
                            onTestPrimary: vm.testBoxCompletedSound,
                            testPrimaryLabel: 'Testar',
                          ),
                          const Divider(height: 1),
                          _SoundSettingRow(
                            title: 'Alerta: Esteira Sem Lote Aberto',
                            value: conveyorAlertSound,
                            onChanged: vm.toggleConveyorAlertSound,
                            onTestPrimary: vm.testConveyorAlertSound,
                            testPrimaryLabel: 'Testar',
                          ),
                          const Divider(height: 1),
                          _SoundSettingRow(
                            title: 'Freezer Iniciando Ciclo (F1 vs F2)',
                            value: freezerStartSound,
                            onChanged: vm.toggleFreezerStartSound,
                            onTestPrimary: () => vm.testFreezerStartSound('f1'),
                            testPrimaryLabel: 'F1',
                            onTestSecondary: () =>
                                vm.testFreezerStartSound('f2'),
                            testSecondaryLabel: 'F2',
                          ),
                          const Divider(height: 1),
                          _SoundSettingRow(
                            title: 'Freezer Pronto para Retirada (F1 vs F2)',
                            value: freezerReadySound,
                            onChanged: vm.toggleFreezerReadySound,
                            onTestPrimary: () => vm.testFreezerReadySound('f1'),
                            testPrimaryLabel: 'F1',
                            onTestSecondary: () =>
                                vm.testFreezerReadySound('f2'),
                            testSecondaryLabel: 'F2',
                          ),
                          const Divider(height: 1),
                          _SoundSettingRow(
                            title: 'Clique de Porta (Abriu / Fechou)',
                            value: doorToggleSound,
                            onChanged: vm.toggleDoorToggleSound,
                            onTestPrimary: vm.testDoorToggleSound,
                            testPrimaryLabel: 'Testar',
                          ),
                          const Divider(height: 1),
                          _SoundSettingRow(
                            title: 'Alarme: Porta Esquecida Aberta',
                            value: doorAlarmSound,
                            onChanged: vm.toggleDoorAlarmSound,
                            onTestPrimary: vm.testDoorAlarmSound,
                            testPrimaryLabel: 'Testar',
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (freezerVm != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: TextButton.icon(
                          onPressed: () async {
                            await freezerVm.resetCalibration('f1');
                            await freezerVm.resetCalibration('f2');
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

final class _FreezerSensorBindingsCard extends StatelessWidget {
  final FreezerMonitoringViewModel freezerViewModel;
  final EggCountViewModel? eggViewModel;
  final String? currentUserEmail;

  const _FreezerSensorBindingsCard({
    required this.freezerViewModel,
    this.eggViewModel,
    this.currentUserEmail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SignalBuilder(
      builder: (context) {
        final equipments = freezerViewModel.availableEquipments.value;
        final isSyncingEq = freezerViewModel.isSyncingEquipments.value;
        final isSyncingProd = eggViewModel?.isSyncingProducts.value ?? false;
        final isSyncing = isSyncingEq || isSyncingProd;
        final f1 = freezerViewModel.freezer1.value;
        final f2 = freezerViewModel.freezer2.value;

        return Card.filled(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VÍNCULO DE FREEZERS (SUPABASE) ↔ SENSORES ESP32',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: colorScheme.primary,
                            ),
                          ),
                          if (currentUserEmail != null)
                            Text(
                              'Supabase: $currentUserEmail',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10.5,
                                color: AppTheme.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          key: const ValueKey('sync_supabase_catalog_btn'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          onPressed: isSyncing
                              ? null
                              : () async {
                                  await Future.wait([
                                    freezerViewModel
                                        .refreshEquipmentsAndBindings(),
                                    if (eggViewModel != null)
                                      eggViewModel!.refreshProducts(),
                                  ]);
                                },
                          icon: isSyncing
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.sync_rounded, size: 14),
                          label: Text(
                            isSyncing ? 'Sincronizando...' : 'Sincronizar',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (currentUserEmail != null)
                          IconButton(
                            key: const ValueKey('supabase_logout_btn'),
                            visualDensity: VisualDensity.compact,
                            iconSize: 16,
                            tooltip: 'Sair da conta Supabase',
                            onPressed: () async {
                              await supabaseOrNull?.auth.signOut();
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            icon: Icon(
                              Icons.logout_rounded,
                              color: colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (f1 != null)
                  _SensorBindingDropdownRow(
                    sensorKey: 'f1',
                    sensorLabel: 'Sensor 1 (F1)',
                    currentEquipmentId: f1.equipmentId,
                    equipments: equipments,
                    onSelect: (eq) => freezerViewModel.bindEquipmentToSensor(
                      sensorKey: 'f1',
                      equipment: eq,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                if (f2 != null)
                  _SensorBindingDropdownRow(
                    sensorKey: 'f2',
                    sensorLabel: 'Sensor 2 (F2)',
                    currentEquipmentId: f2.equipmentId,
                    equipments: equipments,
                    onSelect: (eq) => freezerViewModel.bindEquipmentToSensor(
                      sensorKey: 'f2',
                      equipment: eq,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

final class _SensorBindingDropdownRow extends StatelessWidget {
  final String sensorKey;
  final String sensorLabel;
  final String? currentEquipmentId;
  final List<EquipmentModel> equipments;
  final ValueChanged<EquipmentModel?> onSelect;

  const _SensorBindingDropdownRow({
    required this.sensorKey,
    required this.sensorLabel,
    required this.currentEquipmentId,
    required this.equipments,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasInList =
        currentEquipmentId != null &&
        equipments.any((e) => e.id == currentEquipmentId);
    final selectedId = hasInList ? currentEquipmentId : null;

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Row(
            children: [
              Icon(
                Icons.sensors_rounded,
                size: 15,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  sensorLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: DropdownButtonFormField<String?>(
            key: ValueKey('settings_sensor_binding_$sensorKey'),
            initialValue: selectedId,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusSm,
              ),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  'Não vinculado (Selecionar Freezer)',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              for (final eq in equipments)
                DropdownMenuItem<String?>(
                  value: eq.id,
                  child: Text(
                    eq.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
            onChanged: (id) {
              final chosen = id == null
                  ? null
                  : equipments.where((e) => e.id == id).firstOrNull;
              onSelect(chosen);
            },
          ),
        ),
      ],
    );
  }
}

final class _SoundSettingRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTestPrimary;
  final String testPrimaryLabel;
  final VoidCallback? onTestSecondary;
  final String? testSecondaryLabel;

  const _SoundSettingRow({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.onTestPrimary,
    required this.testPrimaryLabel,
    this.onTestSecondary,
    this.testSecondaryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              minimumSize: const Size(0, 28),
              foregroundColor: colorScheme.primary,
            ),
            onPressed: onTestPrimary,
            icon: const Icon(Icons.volume_up_rounded, size: 14),
            label: Text(
              testPrimaryLabel,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
          if (onTestSecondary != null && testSecondaryLabel != null) ...[
            const SizedBox(width: 2),
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: const Size(0, 28),
                foregroundColor: colorScheme.secondary,
              ),
              onPressed: onTestSecondary,
              icon: const Icon(Icons.volume_up_rounded, size: 14),
              label: Text(
                testSecondaryLabel!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          Transform.scale(
            scale: 0.82,
            child: Switch(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
