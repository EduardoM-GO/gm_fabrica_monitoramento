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
  late final TextEditingController _targetMinController;
  String? _selectedEquipmentId;

  @override
  void initState() {
    super.initState();
    _targetMinController = TextEditingController(
      text: (widget.item.calibratedBaseSeconds.value ~/ 60).toString(),
    );
    _selectedEquipmentId = widget.item.equipmentId.value;

    widget.viewModel.refreshEquipmentsAndBindings();
  }

  @override
  void dispose() {
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
    final leadSec = widget.item.predictedDoorLeadSeconds.value;

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
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '3. MOTOR INTELIGENTE DE PORTA & TEMPERATURA (AUTOMÁTICO)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'O sistema reconhece automaticamente retirada vs. reabastecimento pela assinatura de tempo e salto térmico (ΔT), sem precisar configurar segundos manualmente:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AutoFeatureInfoTile(
              icon: Icons.sync_alt_rounded,
              title: 'Auto-Reconhecimento de Retirada e Recarga',
              subtitle:
                  'Aberturas de troca (≥ 22s ou salto ≥ +2,3 °C) salvam o lote anterior como OK e já iniciam o novo ciclo. Se esvaziar sem reabastecer, toque em "Reiniciar" ou segure o card para marcar "Freezer Vazio".',
              color: colorScheme.secondary,
            ),
            const SizedBox(height: 6),
            _AutoFeatureInfoTile(
              icon: Icons.thermostat_auto_rounded,
              title: 'Tempo Dinâmico pela Temperatura da Câmara',
              subtitle:
                  'Compensa automaticamente quando o freezer inicia quente (+4 °C a +6 °C após várias trocas) ou super gelado (-8 °C no 1º lote), sem sujar a calibração base do produto.',
              color: colorScheme.tertiary,
            ),
            const SizedBox(height: 6),
            _AutoFeatureInfoTile(
              icon: Icons.notifications_active_rounded,
              title: 'Antecipação do Alarme de Pronto (~${leadSec}s antes)',
              subtitle:
                  'Avisa ${leadSec}s antes do fim para descontar o tempo de caminhada até abrir a porta. A calibração base só muda quando você marca "Ainda Mole", "Muito Gelado" ou "Pronto" adiantado.',
              color: AppTheme.successGreen,
            ),
          ],
        ),
      ),
    );
  }
}

final class _AutoFeatureInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _AutoFeatureInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    height: 1.25,
                    color: colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final isTablet = AppBreakpoints.isTabletKiosk(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: IconButton.filledTonal(
            visualDensity:
                isTablet ? VisualDensity.standard : VisualDensity.compact,
            style: isTablet
                ? IconButton.styleFrom(minimumSize: const Size(48, 48))
                : null,
            tooltip: 'Diminuir',
            onPressed: onDecrement,
            icon: Icon(Icons.remove_rounded, size: isTablet ? 22 : 18),
          ),
        ),
        SizedBox(width: isTablet ? AppSpacing.sm : AppSpacing.xs),
        Expanded(
          child: TextField(
            key: fieldKey,
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: isTablet ? 16 : null,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              labelText: labelText,
              helperText: helperText,
              helperMaxLines: 2,
              suffixText: unitLabel,
              isDense: !isTablet,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusSm,
              ),
            ),
          ),
        ),
        SizedBox(width: isTablet ? AppSpacing.sm : AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: IconButton.filledTonal(
            visualDensity:
                isTablet ? VisualDensity.standard : VisualDensity.compact,
            style: isTablet
                ? IconButton.styleFrom(minimumSize: const Size(48, 48))
                : null,
            tooltip: 'Aumentar',
            onPressed: onIncrement,
            icon: Icon(Icons.add_rounded, size: isTablet ? 22 : 18),
          ),
        ),
      ],
    );
  }
}
