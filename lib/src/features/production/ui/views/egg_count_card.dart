import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_motion.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/status_badge.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/adjustment_reason_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/ui/view_models/egg_count_view_model.dart';
import 'package:signals/signals_flutter.dart';

final class EggCountCard extends StatelessWidget {
  final EggCountViewModel viewModel;

  const EggCountCard({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SignalBuilder(
      builder: (context) {
        final isAnimating = viewModel.isHitAnimating.value;
        final isConveyorAlert = viewModel.isConveyorRunningWithoutBatch.value;
        final hasBatch = viewModel.hasActiveBatch.value;
        final currentBox = viewModel.currentBoxCount.value;
        final boxCap = viewModel.defaultBoxCapacity.value;
        final progress = viewModel.boxProgress.value;
        final speed = viewModel.eggsPerMinute.value;
        final completedBoxes = viewModel.batchCompletedBoxes.value;

        return Card.outlined(
          color: isConveyorAlert
              ? colorScheme.errorContainer.withValues(alpha: 0.28)
              : colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusXl,
            side: BorderSide(
              color: isConveyorAlert
                  ? colorScheme.error
                  : isAnimating
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
              width: (isAnimating || isConveyorAlert) ? 2.0 : 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Alerta de Esteira Rodando Sem Lote Ativo ---
                if (isConveyorAlert) ...[
                  BreathingGlow(
                    isPulsing: true,
                    child: Card.filled(
                      color: colorScheme.errorContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                        side: BorderSide(color: colorScheme.error),
                      ),
                      child: InkWell(
                        borderRadius: AppSpacing.borderRadiusMd,
                        onTap: () => _showProductSelectorSheet(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: colorScheme.onErrorContainer,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Esteira em movimento sem lote aberto! Toque para selecionar o produto.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],

                // --- Header: Produto atual & Cadência da Esteira ---
                Row(
                  children: [
                    AnimatedScale(
                      scale: isAnimating ? 1.14 : 1.0,
                      duration: AppMotion.durationFast,
                      curve: AppMotion.easeOut,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: hasBatch
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest.withValues(
                                  alpha: 0.45,
                                ),
                          borderRadius: AppSpacing.borderRadiusSm,
                          border: Border.all(
                            color: hasBatch
                                ? colorScheme.primary.withValues(alpha: 0.5)
                                : colorScheme.outlineVariant.withValues(
                                    alpha: 0.4,
                                  ),
                          ),
                        ),
                        child: Icon(
                          Icons.egg_rounded,
                          color: hasBatch
                              ? colorScheme.onPrimaryContainer
                              : AppTheme.textMuted,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  viewModel.productName.value.toUpperCase(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontFamily: AppTheme.fontHeading,
                                    fontWeight: FontWeight.w900,
                                    fontSize: hasBatch ? 16 : 14,
                                    letterSpacing: 0.5,
                                    color: hasBatch
                                        ? colorScheme.onSurface
                                        : AppTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              StatusBadge(
                                label: hasBatch ? 'LOTE ATIVO' : 'EM REPOUSO',
                                color: hasBatch
                                    ? AppTheme.successGreen
                                    : AppTheme.textMuted,
                                compact: true,
                                subtle: !hasBatch,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasBatch
                                ? 'Caixa #${completedBoxes + 1} em enchimento • Capacidade: $boxCap ovos ($completedBoxes cx no lote)'
                                : 'Selecione um produto para iniciar a contagem na esteira',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10.5,
                              color: AppTheme.textMuted,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // Cadência da esteira (Tier 3 quando parada, Tier 2 em movimento)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: speed > 0
                            ? colorScheme.surfaceContainerHigh
                            : colorScheme.surfaceContainerLowest.withValues(
                                alpha: 0.5,
                              ),
                        borderRadius: AppSpacing.borderRadiusXs,
                        border: Border.all(
                          color: speed > 0
                              ? colorScheme.primary.withValues(alpha: 0.4)
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.35,
                                ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.speed_rounded,
                            size: 13,
                            color: speed > 0
                                ? colorScheme.primary
                                : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${speed.toStringAsFixed(0)} ovos/min',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              fontWeight: speed > 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: speed > 0
                                  ? colorScheme.onSurface
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xs),

                // --- Display Central Hero (Tier 1): Contador da Caixa em Enchimento ---
                Card.filled(
                  color: colorScheme.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusLg,
                    side: BorderSide(
                      color: isAnimating
                          ? colorScheme.primary
                          : hasBatch
                              ? colorScheme.primary.withValues(alpha: 0.35)
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                      width: isAnimating ? 2.0 : 1.2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            SlidingCounterText(
                              value: currentBox,
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontFamily: AppTheme.fontHeading,
                                fontWeight: FontWeight.w900,
                                fontSize: 64,
                                height: 1.0,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                color: hasBatch
                                    ? colorScheme.primary
                                    : AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '/ $boxCap ovos',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SmoothProgressBar(
                          value: progress,
                          minHeight: 10,
                          progressColor: progress >= 1.0
                              ? AppTheme.successGreen
                              : colorScheme.primary,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          borderRadius: AppSpacing.borderRadiusXs,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                // --- Barra de Ações: Ação Frequente em Destaque vs. Rotina Rara Tímida ---
                if (!hasBatch)
                  PressableScale(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                      ),
                      onPressed: () => _showProductSelectorSheet(context),
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: const Text(
                        'INICIAR LOTE DE PRODUÇÃO',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      // Ação operacional frequente (Tier 1/2): Grande e chamativa
                      Expanded(
                        flex: 5,
                        child: PressableScale(
                          child: FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(42),
                              backgroundColor: colorScheme.errorContainer
                                  .withValues(alpha: 0.78),
                              foregroundColor: colorScheme.onErrorContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppSpacing.borderRadiusMd,
                                side: BorderSide(
                                  color: colorScheme.error.withValues(
                                    alpha: 0.65,
                                  ),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            onPressed: () => _showDiscardSheet(context),
                            icon: const Icon(
                              Icons.broken_image_outlined,
                              size: 18,
                            ),
                            label: const Text(
                              'LANÇAR QUEBRA',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      // Rotina pouco usada (Tier 3): Tímida e compacta para evitar toque acidental
                      Expanded(
                        flex: 2,
                        child: PressableScale(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(42),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              foregroundColor: AppTheme.textMuted,
                              side: BorderSide(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppSpacing.borderRadiusMd,
                              ),
                            ),
                            onPressed: () => _showProductSelectorSheet(context),
                            icon: Icon(
                              Icons.stop_circle_outlined,
                              size: 14,
                              color: AppTheme.textMuted.withValues(alpha: 0.8),
                            ),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'ENCERRAR LOTE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10.5,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: AppSpacing.xs),

                // --- Painel de Contabilidade do Dia: Hierarquia entre Métricas Principais e Secundárias ---
                Row(
                  children: [
                    // Principais para o operador (Líquido e Caixas Fechadas): Maior destaque (flex 6)
                    Expanded(
                      flex: 6,
                      child: _StatItem(
                        label: 'LÍQUIDO DO DIA',
                        value: '${viewModel.dailyNetCount.value}',
                        icon: Icons.verified_rounded,
                        color: colorScheme.primary,
                        isHighlight: true,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 6,
                      child: _StatItem(
                        label: 'CAIXAS FECHADAS',
                        value: '${viewModel.dailyCompletedBoxes.value}',
                        icon: Icons.inventory_2_rounded,
                        color: colorScheme.secondary,
                        isHighlight: true,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Secundárias / conferência (Bruto e Quebras): Mais tímidas (flex 4)
                    Expanded(
                      flex: 4,
                      child: _StatItem(
                        label: 'TOTAL BRUTO',
                        value: '${viewModel.dailyGrossCount.value}',
                        icon: Icons.precision_manufacturing_rounded,
                        color: AppTheme.textSecondary,
                        isSubtle: true,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 4,
                      child: _StatItem(
                        label: 'QUEBRAS/DESC.',
                        value: '${viewModel.dailyDiscardsCount.value}',
                        icon: Icons.heart_broken_rounded,
                        color: viewModel.dailyDiscardsCount.value > 0
                            ? colorScheme.error.withValues(alpha: 0.85)
                            : AppTheme.textMuted,
                        isSubtle: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProductSelectorSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 720),
      backgroundColor: colorScheme.surfaceContainerHigh,
      builder: (sheetCtx) {
        return SignalBuilder(
          builder: (ctx) {
            final products = viewModel.availableProducts.value;
            final activeBatch = viewModel.activeBatch.value;
            final isLocked = activeBatch != null;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                                isLocked
                                    ? 'LOTE EM ANDAMENTO'
                                    : 'SELECIONAR PRODUTO DO LOTE',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontFamily: AppTheme.fontHeading,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                isLocked
                                    ? 'Encerre o lote atual antes de iniciar outro produto na esteira'
                                    : 'Toque em um item do catálogo para iniciar a OP na esteira',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isLocked) ...[
                          const SizedBox(width: AppSpacing.xs),
                          FilledButton.tonalIcon(
                            key: const ValueKey('finish_active_batch_btn'),
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.errorContainer,
                              foregroundColor: colorScheme.onErrorContainer,
                            ),
                            onPressed: () async {
                              await viewModel.finishActiveBatch();
                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                            },
                            icon: const Icon(
                              Icons.stop_circle_outlined,
                              size: 18,
                            ),
                            label: const Text('Encerrar Lote Atual'),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final product in products)
                          Builder(
                            builder: (_) {
                              final isCurrent =
                                  activeBatch?.product.id == product.id;

                              return Opacity(
                                opacity: (!isLocked || isCurrent) ? 1.0 : 0.45,
                                child: SizedBox(
                                  width: 220,
                                  child: Card.outlined(
                                    color: isCurrent
                                        ? colorScheme.primaryContainer
                                        : colorScheme.surfaceContainerHighest,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppSpacing.borderRadiusMd,
                                      side: BorderSide(
                                        color: isCurrent
                                            ? colorScheme.primary
                                            : colorScheme.outlineVariant,
                                        width: isCurrent ? 1.8 : 1.0,
                                      ),
                                    ),
                                    child: InkWell(
                                      borderRadius: AppSpacing.borderRadiusMd,
                                      onTap: isLocked
                                          ? null
                                          : () async {
                                              await viewModel.startBatch(
                                                product,
                                              );
                                              if (sheetCtx.mounted) {
                                                Navigator.pop(sheetCtx);
                                              }
                                            },
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                          AppSpacing.sm,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    product.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme
                                                        .titleSmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: isCurrent
                                                              ? colorScheme
                                                                    .onPrimaryContainer
                                                              : colorScheme
                                                                    .onSurface,
                                                        ),
                                                  ),
                                                ),
                                                if (isCurrent)
                                                  Icon(
                                                    Icons.check_circle_rounded,
                                                    size: 16,
                                                    color: colorScheme.primary,
                                                  )
                                                else if (isLocked)
                                                  Icon(
                                                    Icons.lock_outline_rounded,
                                                    size: 15,
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.xxs,
                                            ),
                                            Text(
                                              '${product.unitWeightGrams}g • Caixa: ${product.defaultBoxCapacity} un',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: isCurrent
                                                        ? colorScheme
                                                              .onPrimaryContainer
                                                              .withValues(
                                                                alpha: 0.85,
                                                              )
                                                        : colorScheme
                                                              .onSurfaceVariant,
                                                    fontFeatures: const [
                                                      FontFeature.tabularFigures(),
                                                    ],
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDiscardSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 720),
      backgroundColor: colorScheme.surfaceContainerHigh,
      builder: (sheetCtx) {
        return _DiscardBottomSheet(viewModel: viewModel);
      },
    );
  }
}

final class _DiscardBottomSheet extends StatefulWidget {
  final EggCountViewModel viewModel;

  const _DiscardBottomSheet({required this.viewModel});

  @override
  State<_DiscardBottomSheet> createState() => _DiscardBottomSheetState();
}

class _DiscardBottomSheetState extends State<_DiscardBottomSheet> {
  AdjustmentReasonEnum _selectedReason = AdjustmentReasonEnum.brokenShell;
  final TextEditingController _customQtyController = TextEditingController();

  @override
  void dispose() {
    _customQtyController.dispose();
    super.dispose();
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isAddition = _selectedReason.isAddition;
    final signPrefix = isAddition ? '+' : '-';
    final actionColor = isAddition ? AppTheme.successGreen : colorScheme.error;
    final buttonBgColor = isAddition
        ? AppTheme.successGreen.withValues(alpha: 0.22)
        : colorScheme.errorContainer;
    final buttonFgColor = isAddition
        ? AppTheme.successGreen
        : colorScheme.onErrorContainer;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.lg + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'LANÇAR QUEBRA / DESCARTE',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: AppTheme.fontHeading,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                StatusBadge(
                  label: isAddition
                      ? 'SOMAR À CONTAGEM (+)'
                      : 'SUBTRAIR QUEBRA (-)',
                  color: actionColor,
                  icon: isAddition
                      ? Icons.add_circle_outline_rounded
                      : Icons.remove_circle_outline_rounded,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              isAddition
                  ? 'Correção manual adiciona ovos não lidos pelo sensor da esteira:'
                  : 'Selecione o tipo de lançamento e use os atalhos ou digite a quantidade:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<AdjustmentReasonEnum>(
              key: const ValueKey('adjustment_reason_dropdown'),
              initialValue: _selectedReason,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Tipo de Lançamento',
                isDense: true,
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
                    child: Row(
                      children: [
                        Icon(
                          reason.isAddition
                              ? Icons.add_circle_rounded
                              : Icons.remove_circle_rounded,
                          size: 16,
                          color: reason.isAddition
                              ? AppTheme.successGreen
                              : colorScheme.error,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            reason.isAddition
                                ? '${reason.label} (Adicionar +)'
                                : '${reason.label} (Subtrair -)',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedReason = value);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (final qty in [1, 2]) ...[
                  Expanded(
                    flex: 2,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 48,
                    child: TextField(
                      key: const ValueKey('discard_custom_qty_input'),
                      controller: _customQtyController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSubmitted: (_) => _submitCustomQty(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        labelText: isAddition
                            ? 'Qtd. a somar (+)'
                            : 'Digitar qtd. (-)',
                        hintText: 'Ex: 5',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        suffixIcon: IconButton.filled(
                          key: const ValueKey('discard_custom_qty_submit'),
                          tooltip: 'Confirmar quantidade',
                          style: IconButton.styleFrom(
                            backgroundColor: actionColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSpacing.borderRadiusXs,
                            ),
                          ),
                          onPressed: _submitCustomQty,
                          icon: const Icon(Icons.check_rounded, size: 18),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isHighlight;
  final bool isSubtle;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isHighlight = false,
    this.isSubtle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card.filled(
      color: isHighlight
          ? colorScheme.surfaceContainerHigh
          : isSubtle
              ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.45)
              : colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusSm,
        side: BorderSide(
          color: isHighlight
              ? color.withValues(alpha: 0.55)
              : isSubtle
                  ? colorScheme.outlineVariant.withValues(alpha: 0.30)
                  : colorScheme.outlineVariant,
          width: isHighlight ? 1.2 : 1.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: isHighlight ? 6 : 4,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: isSubtle ? 9.5 : 11,
                    color: isSubtle ? color.withValues(alpha: 0.7) : color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: isSubtle ? 8.5 : 9.5,
                      fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0.35,
                      color: isHighlight
                          ? AppTheme.textSecondary
                          : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isSubtle ? FontWeight.w700 : FontWeight.w900,
                  fontSize: isHighlight ? 19 : 13.5,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
