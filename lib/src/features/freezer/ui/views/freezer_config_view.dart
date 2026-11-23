import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_breakpoints.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/kiosk_subpage_header.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/status_badge.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/freezer_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/ui/view_models/freezer_monitoring_view_model.dart';
import 'package:signals/signals_flutter.dart';

/// Tela completa para configuração de vínculo do sensor ESP32 com equipamento do Supabase
/// e calibração dos tempos de porta e ciclo do Freezer.
/// Otimizada para Kiosk Horizontal (~800x360 dp) com steppers (+/-) de toque amplo.
final class FreezerConfigView extends StatefulWidget {
  final FreezerMonitoringViewModel viewModel;
  final FreezerItemSignals item;

  const FreezerConfigView({
    super.key,
    required this.viewModel,
    required this.item,
  });

  @override
  State<FreezerConfigView> createState() => _FreezerConfigViewState();
}

class _FreezerConfigViewState extends State<FreezerConfigView> {
  late final TextEditingController _unloadController;
  late final TextEditingController _reloadController;
  late final TextEditingController _targetMinController;
  String? _selectedEquipmentId;

  @override
  void initState() {
    super.initState();
    _unloadController = TextEditingController(
      text: widget.item.unloadMinSeconds.value.toString(),
    );
    _reloadController = TextEditingController(
      text: widget.item.reloadMinSeconds.value.toString(),
    );
    _targetMinController = TextEditingController(
      text: (widget.item.calibratedBaseSeconds.value ~/ 60).toString(),
    );
    _selectedEquipmentId = widget.item.equipmentId.value;

    widget.viewModel.refreshEquipmentsAndBindings();
  }

  @override
  void dispose() {
    _unloadController.dispose();
    _reloadController.dispose();
    _targetMinController.dispose();
    super.dispose();
  }

  void _stepController(
    TextEditingController controller, {
    required int delta,
    required int min,
    required int max,
  }) {
    final current = int.tryParse(controller.text.trim()) ?? min;
    final next = (current + delta).clamp(min, max);
    setState(() {
      controller.text = next.toString();
    });
  }

  void _saveAndClose(List<EquipmentModel> equipments) {
    final unload =
        int.tryParse(_unloadController.text.trim()) ??
        widget.item.unloadMinSeconds.value;
    final reload =
        int.tryParse(_reloadController.text.trim()) ??
        widget.item.reloadMinSeconds.value;
    final targetMin =
        int.tryParse(_targetMinController.text.trim()) ??
        (widget.item.calibratedBaseSeconds.value ~/ 60);

    EquipmentModel? chosenEq;
    if (_selectedEquipmentId != null) {
      chosenEq = equipments
          .where((e) => e.id == _selectedEquipmentId)
          .firstOrNull;
    }

    widget.viewModel.updateDoorTimingConfig(
      widget.item.freezerId,
      unloadMinSeconds: unload,
      reloadMinSeconds: reload,
      targetDurationSeconds: targetMin * 60,
      linkedEquipment: chosenEq,
      updateEquipmentBinding: true,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final item = widget.item;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        top: false,
        bottom: false,
        child: SignalBuilder(
          builder: (context) {
            final equipments = widget.viewModel.availableEquipments.value;
            final isSyncing = widget.viewModel.isSyncingEquipments.value;
            final hasSelectedInList =
                _selectedEquipmentId != null &&
                equipments.any((e) => e.id == _selectedEquipmentId);
            final effectiveEquipmentId = hasSelectedInList
                ? _selectedEquipmentId
                : null;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KioskSubpageHeader(
                    title:
                        'CONFIGURAR SENSOR ${item.sensorIndex.value} (${item.freezerId.toUpperCase()}) — ${item.name.value.toUpperCase()}',
                    subtitle:
                        'Vínculo com Centro de Custo Supabase e Calibração de Tempos de Porta',
                    icon: Icons.tune_rounded,
                    freezerViewModel: widget.viewModel,
                    backLabel: 'Cancelar',
                    actions: [
                      SignalBuilder(
                        builder: (_) {
                          return StatusBadge(
                            label:
                                '${item.formattedTemp.value} • ${item.isDoorOpen.value ? "PORTA ABERTA" : "PORTA FECHADA"}',
                            color: item.isDoorOpen.value
                                ? colorScheme.error
                                : AppTheme.successGreen,
                            icon: Icons.ac_unit_rounded,
                            compact: true,
                          );
                        },
                      ),
                      FilledButton.icon(
                        key: const ValueKey('save_door_timing_btn'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                        ),
                        onPressed: () => _saveAndClose(equipments),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text(
                          'Salvar',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide =
                            constraints.maxWidth >= AppBreakpoints.compactMax;

                        final leftColumn = _buildEquipmentAndTargetCard(
                          context,
                          theme,
                          colorScheme,
                          equipments: equipments,
                          effectiveEquipmentId: effectiveEquipmentId,
                          isSyncing: isSyncing,
                        );

                        final rightColumn = _buildDoorTimingCard(
                          context,
                          theme,
                          colorScheme,
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 48,
                                child: SingleChildScrollView(child: leftColumn),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                flex: 52,
                                child: SingleChildScrollView(
                                  child: rightColumn,
                                ),
                              ),
                            ],
                          );
                        }

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              leftColumn,
                              const SizedBox(height: AppSpacing.sm),
                              rightColumn,
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEquipmentAndTargetCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required List<EquipmentModel> equipments,
    required String? effectiveEquipmentId,
    required bool isSyncing,
  }) {
    final item = widget.item;

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
                  child: Text(
                    '1. EQUIPAMENTO VINCULADO (SUPABASE)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                  ),
                  onPressed: isSyncing
                      ? null
                      : () => widget.viewModel.refreshEquipmentsAndBindings(),
                  icon: isSyncing
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded, size: 14),
                  label: Text(
                    isSyncing ? 'Sincronizando...' : 'Atualizar Lista',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              key: ValueKey('freezer_equipment_dropdown_${item.freezerId}'),
              initialValue: effectiveEquipmentId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Equipamento Vinculado (Supabase / Centros de Custo)',
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sem equipamento vinculado'),
                ),
                for (final eq in equipments)
                  DropdownMenuItem<String?>(
                    value: eq.id,
                    child: Text(
                      eq.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedEquipmentId = val;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '2. TEMPO ALVO DO CICLO DE CRISTALIZAÇÃO',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                color: colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 6),
            _NumericStepperField(
              fieldKey: const ValueKey('input_target_minutes'),
              controller: _targetMinController,
              labelText: 'Tempo Alvo Base (minutos)',
              helperText:
                  'Tempo padrão de geladeira antes das compensações térmicas',
              unitLabel: 'min',
              onDecrement: () => _stepController(
                _targetMinController,
                delta: -1,
                min: 1,
                max: 180,
              ),
              onIncrement: () => _stepController(
                _targetMinController,
                delta: 1,
                min: 1,
                max: 180,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () async {
                  await widget.viewModel.resetCalibration(item.freezerId);
                  if (!context.mounted) return;
                  setState(() {
                    _targetMinController.text =
                        (item.calibratedBaseSeconds.value ~/ 60).toString();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Calibração adaptativa deste freezer restaurada para o padrão.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.restore_rounded, size: 16),
                label: const Text(
                  'Restaurar Tempo Base Padrão (8 min)',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoorTimingCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
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
            Text(
              '3. DETECÇÃO AUTOMÁTICA DE PORTA (RETIRADA VS RECARGA)',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Configure quantos segundos de porta aberta diferenciam uma rápida inspeção, a retirada do lote pronto ou uma nova recarga:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NumericStepperField(
              fieldKey: const ValueKey('input_unload_seconds'),
              controller: _unloadController,
              labelText: 'Tempo mín. Só Retirada (segundos)',
              helperText:
                  'Abaixo disso com lote pronto = "Verificação / Ainda Mole"',
              unitLabel: 'seg',
              onDecrement: () => _stepController(
                _unloadController,
                delta: -1,
                min: 2,
                max: 300,
              ),
              onIncrement: () => _stepController(
                _unloadController,
                delta: 1,
                min: 2,
                max: 300,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NumericStepperField(
              fieldKey: const ValueKey('input_reload_seconds'),
              controller: _reloadController,
              labelText: 'Tempo mín. Retirou + Abasteceu (segundos)',
              helperText:
                  'Acima disso = encerra o lote atual e já inicia nova contagem',
              unitLabel: 'seg',
              onDecrement: () => _stepController(
                _reloadController,
                delta: -2,
                min: 4,
                max: 600,
              ),
              onIncrement: () => _stepController(
                _reloadController,
                delta: 2,
                min: 4,
                max: 600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _NumericStepperField extends StatelessWidget {
  final Key fieldKey;
  final TextEditingController controller;
  final String labelText;
  final String? helperText;
  final String unitLabel;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _NumericStepperField({
    required this.fieldKey,
    required this.controller,
    required this.labelText,
    this.helperText,
    required this.unitLabel,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: IconButton.filledTonal(
            visualDensity: VisualDensity.compact,
            tooltip: 'Diminuir',
            onPressed: onDecrement,
            icon: const Icon(Icons.remove_rounded, size: 18),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: TextField(
            key: fieldKey,
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              labelText: labelText,
              helperText: helperText,
              helperMaxLines: 2,
              suffixText: unitLabel,
              isDense: true,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusSm,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: IconButton.filledTonal(
            visualDensity: VisualDensity.compact,
            tooltip: 'Aumentar',
            onPressed: onIncrement,
            icon: const Icon(Icons.add_rounded, size: 18),
          ),
        ),
      ],
    );
  }
}
