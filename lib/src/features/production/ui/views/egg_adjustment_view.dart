import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_breakpoints.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/kiosk_subpage_header.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/status_badge.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/adjustment_reason_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/ui/view_models/egg_count_view_model.dart';
import 'package:signals/signals_flutter.dart';

/// Tela completa para Ajuste de Contagem, Registro de Quebras e Correção Manual.
/// Substitui o antigo BottomSheet por um layout de 2 colunas em tela cheia:
/// - Coluna Esquerda: Seleção rápida por toque (Cards) + Dropdown compatível de Tipo de Lançamento e resumo ao vivo.
/// - Coluna Direita: Atalhos rápidos (+1/-1, +2/-2, +5/-5) + Stepper e campo de quantidade customizada.
final class EggAdjustmentView extends StatefulWidget {
  final EggCountViewModel viewModel;

  const EggAdjustmentView({super.key, required this.viewModel});

  @override
  State<EggAdjustmentView> createState() => _EggAdjustmentViewState();
}

class _EggAdjustmentViewState extends State<EggAdjustmentView> {
  AdjustmentReasonEnum _selectedReason = AdjustmentReasonEnum.brokenShell;
  final TextEditingController _customQtyController = TextEditingController();

  @override
  void dispose() {
    _customQtyController.dispose();
    super.dispose();
  }

  void _stepCustomQty(int delta) {
    final current = int.tryParse(_customQtyController.text.trim()) ?? 0;
    final next = (current + delta).clamp(1, 999);
    setState(() {
      _customQtyController.text = next.toString();
    });
  }

  Future<void> _submitCustomQty() async {
    final qty = int.tryParse(_customQtyController.text.trim());
    if (qty == null || qty <= 0) return;

    await widget.viewModel.addDiscards(
      reason: _selectedReason,
      quantity: qty,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = AppBreakpoints.isTabletKiosk(context);
    final isAddition = _selectedReason.isAddition;
    final signPrefix = isAddition ? '+' : '-';
    final actionColor = isAddition ? AppTheme.successGreen : colorScheme.error;
    final buttonBgColor = isAddition
        ? AppTheme.successGreen.withValues(alpha: 0.22)
        : colorScheme.errorContainer;
    final buttonFgColor = isAddition
        ? AppTheme.successGreen
        : colorScheme.onErrorContainer;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? AppSpacing.md : AppSpacing.sm,
            vertical: isTablet ? AppSpacing.xs : 6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KioskSubpageHeader(
                title: 'AJUSTAR CONTAGEM / DESCARTE',
                subtitle: isAddition
                    ? 'Correção manual adiciona ovos não lidos pelo sensor da esteira'
                    : 'Registre ovos quebrados ou com defeito para descontar da caixa atual',
                icon: Icons.exposure_rounded,
                eggViewModel: widget.viewModel,
                backLabel: 'Voltar',
                actions: [
                  StatusBadge(
                    label: isAddition
                        ? 'SOMAR À CONTAGEM (+)'
                        : 'SUBTRAIR QUEBRA (-)',
                    color: actionColor,
                    icon: isAddition
                        ? Icons.add_circle_outline_rounded
                        : Icons.remove_circle_outline_rounded,
                    compact: !isTablet,
                  ),
                ],
              ),
              SizedBox(height: isTablet ? AppSpacing.sm : 6),

              // Faixa de Resumo Ao Vivo da Produção
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? AppSpacing.md : AppSpacing.sm,
                  vertical: isTablet ? 10 : 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SignalBuilder(
                        builder: (context) {
                          final box = widget.viewModel.currentBoxCount.value;
                          final cap = widget.viewModel.defaultBoxCapacity.value;
                          return Text(
                            'Caixa Atual: $box / $cap',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: AppSpacing.md),
                      SignalBuilder(
                        builder: (context) {
                          final gross = widget.viewModel.dailyGrossCount.value;
                          return Text(
                            'Total Bruto: $gross',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: AppSpacing.md),
                      SignalBuilder(
                        builder: (context) {
                          final discards =
                              widget.viewModel.dailyDiscardsCount.value;
                          return Text(
                            'Quebras/Desc.: $discards',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: discards > 0
                                  ? colorScheme.error
                                  : AppTheme.textSecondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: AppSpacing.md),
                      SignalBuilder(
                        builder: (context) {
                          final speed = widget.viewModel.eggsPerMinute.value;
                          return Text(
                            'Cadência: ${speed.toStringAsFixed(0)} ovos/min',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMuted,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Corpo Principal em 2 Colunas (Motivo à esquerda | Quantidades à direita)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide =
                        constraints.maxWidth >= AppBreakpoints.compactMax;

                    final reasonPanel = _buildReasonColumn(
                      context,
                      theme,
                      colorScheme,
                    );
                    final quantityPanel = _buildQuantityColumn(
                      context,
                      theme,
                      colorScheme,
                      isAddition: isAddition,
                      signPrefix: signPrefix,
                      actionColor: actionColor,
                      buttonBgColor: buttonBgColor,
                      buttonFgColor: buttonFgColor,
                    );

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 48,
                            child: SingleChildScrollView(child: reasonPanel),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: 52,
                            child: SingleChildScrollView(child: quantityPanel),
                          ),
                        ],
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          reasonPanel,
                          const SizedBox(height: AppSpacing.sm),
                          quantityPanel,
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonColumn(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isTablet = AppBreakpoints.isTabletKiosk(context);

    return Card.filled(
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? AppSpacing.md : AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '1. TIPO DE LANÇAMENTO / MOTIVO',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: isTablet ? 13 : null,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: isTablet ? AppSpacing.sm : 6),
            DropdownButtonFormField<AdjustmentReasonEnum>(
              key: const ValueKey('adjustment_reason_dropdown'),
              initialValue: _selectedReason,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Tipo de Lançamento',
                isDense: !isTablet,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
              ),
              items: [
                for (final reason in AdjustmentReasonEnum.values)
                  DropdownMenuItem<AdjustmentReasonEnum>(
                    value: reason,
                    child: Text(
                      reason.isAddition
                          ? '${reason.label} (Adicionar +)'
                          : '${reason.label} (Subtrair -)',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12.5,
                        fontWeight: FontWeight.w700,
                        color: reason.isAddition
                            ? AppTheme.successGreen
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedReason = value);
                }
              },
            ),
            SizedBox(height: isTablet ? AppSpacing.sm : AppSpacing.xs),
            Text(
              'Ou toque direto em um motivo abaixo:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: isTablet ? 12.5 : 10.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: isTablet ? AppSpacing.sm : 6),
            Wrap(
              spacing: isTablet ? 10 : 6,
              runSpacing: isTablet ? 10 : 6,
              children: [
                for (final reason in AdjustmentReasonEnum.values)
                  ChoiceChip(
                    label: Text(
                      reason.isAddition
                          ? '+ ${reason.label}'
                          : '- ${reason.label}',
                      style: TextStyle(
                        fontSize: isTablet ? 13.5 : 11.5,
                        fontWeight: FontWeight.w800,
                        color: _selectedReason == reason
                            ? (reason.isAddition
                                  ? AppTheme.successGreen
                                  : colorScheme.onErrorContainer)
                            : colorScheme.onSurface,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 12 : 6,
                      vertical: isTablet ? 8 : 2,
                    ),
                    selected: _selectedReason == reason,
                    selectedColor: reason.isAddition
                        ? AppTheme.successGreen.withValues(alpha: 0.24)
                        : colorScheme.errorContainer,
                    visualDensity: isTablet
                        ? VisualDensity.standard
                        : VisualDensity.compact,
                    onSelected: (_) {
                      setState(() => _selectedReason = reason);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityColumn(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required bool isAddition,
    required String signPrefix,
    required Color actionColor,
    required Color buttonBgColor,
    required Color buttonFgColor,
  }) {
    final isTablet = AppBreakpoints.isTabletKiosk(context);
    final quickValues = isTablet ? const [1, 2, 5, 10] : const [1, 2, 5];

    return Card.filled(
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? AppSpacing.md : AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '2. ATALHOS DE LANÇAMENTO IMEDIATO (1 TOQUE)',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: isTablet ? 13 : null,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                color: actionColor,
              ),
            ),
            SizedBox(height: isTablet ? AppSpacing.sm : 6),
            Row(
              children: [
                for (final qty in quickValues) ...[
                  if (qty > 1)
                    SizedBox(width: isTablet ? AppSpacing.sm : AppSpacing.xs),
                  Expanded(
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(isTablet ? 60 : 48),
                        backgroundColor: buttonBgColor,
                        foregroundColor: buttonFgColor,
                      ),
                      onPressed: () async {
                        await widget.viewModel.addDiscards(
                          reason: _selectedReason,
                          quantity: qty,
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$signPrefix$qty ${qty == 1 ? "Ovo" : "Ovos"}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: isTablet ? 16 : 14,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: isTablet ? AppSpacing.md : AppSpacing.sm),
            const Divider(height: 1),
            SizedBox(height: isTablet ? AppSpacing.md : AppSpacing.sm),
            Text(
              '3. QUANTIDADE PERSONALIZADA',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: isTablet ? 13 : null,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: isTablet ? AppSpacing.sm : 6),
            Row(
              children: [
                IconButton.filledTonal(
                  visualDensity: isTablet
                      ? VisualDensity.standard
                      : VisualDensity.compact,
                  style: isTablet
                      ? IconButton.styleFrom(minimumSize: const Size(52, 52))
                      : null,
                  tooltip: 'Diminuir quantidade',
                  onPressed: () => _stepCustomQty(-1),
                  icon: Icon(Icons.remove_rounded, size: isTablet ? 22 : 18),
                ),
                SizedBox(width: isTablet ? AppSpacing.sm : AppSpacing.xs),
                Expanded(
                  child: SizedBox(
                    height: isTablet ? 54 : 46,
                    child: TextField(
                      key: const ValueKey('discard_custom_qty_input'),
                      controller: _customQtyController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSubmitted: (_) => _submitCustomQty(),
                      style: TextStyle(
                        fontSize: isTablet ? 16 : null,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        labelText: isAddition
                            ? 'Qtd. a somar (+)'
                            : 'Qtd. a descontar (-)',
                        hintText: 'Ex: 5',
                        isDense: !isTablet,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: isTablet ? 14 : 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        suffixIcon: IconButton(
                          key: const ValueKey('discard_custom_qty_submit'),
                          tooltip: 'Confirmar lançamento',
                          onPressed: _submitCustomQty,
                          icon: Icon(
                            Icons.check_circle_rounded,
                            size: isTablet ? 24 : 20,
                            color: actionColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? AppSpacing.sm : AppSpacing.xs),
                IconButton.filledTonal(
                  visualDensity: isTablet
                      ? VisualDensity.standard
                      : VisualDensity.compact,
                  style: isTablet
                      ? IconButton.styleFrom(minimumSize: const Size(52, 52))
                      : null,
                  tooltip: 'Aumentar quantidade',
                  onPressed: () => _stepCustomQty(1),
                  icon: Icon(Icons.add_rounded, size: isTablet ? 22 : 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
