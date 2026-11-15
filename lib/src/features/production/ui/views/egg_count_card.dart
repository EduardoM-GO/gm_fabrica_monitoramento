import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_motion.dart';
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

        return Card(
          color: isConveyorAlert
              ? colorScheme.errorContainer.withValues(alpha: 0.25)
              : colorScheme.surfaceContainer,
          elevation: isAnimating ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Alerta de Esteira Rodando Sem Lote Ativo
                if (isConveyorAlert) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showProductSelectorSheet(context),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.error),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: colorScheme.onErrorContainer,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Esteira em movimento sem lote aberto! Toque para selecionar o produto.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Header: Produto atual & Velocidade
                Row(
                  children: [
                    AnimatedScale(
                      scale: isAnimating ? 1.14 : 1.0,
                      duration: AppMotion.durationFast,
                      curve: AppMotion.easeOut,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.egg_rounded,
                          color: colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            viewModel.productName.value.toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            hasBatch
                                ? 'Lote em andamento • Caixa de $boxCap ovos (${viewModel.batchCompletedBoxes.value} cx no lote)'
                                : 'Produção em repouso',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.speed_rounded,
                            size: 16,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${speed.toStringAsFixed(0)} ovos/min',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Contagem Principal da Caixa Atual
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$currentBox',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 64,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: hasBatch
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '/ $boxCap ovos',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Barra de Progresso da Caixa
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      progress >= 1.0
                          ? colorScheme.secondary
                          : colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // --- Barra de Ações Rápidas do Operador (Kiosk 1-Toque) ---
                if (!hasBatch)
                  PressableScale(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _showProductSelectorSheet(context),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'INICIAR LOTE DE PRODUÇÃO',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: PressableScale(
                          child: FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(42),
                              backgroundColor: colorScheme.errorContainer
                                  .withValues(alpha: 0.45),
                              foregroundColor: colorScheme.error,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PressableScale(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(42),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _showProductSelectorSheet(context),
                            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                            label: const Text(
                              'TROCAR / FECHAR LOTE',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // --- Painel Consolidado de Contabilidade do Dia ---
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'TOTAL BRUTO',
                        value: '${viewModel.dailyGrossCount.value}',
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'QUEBRAS/DESC.',
                        value: '${viewModel.dailyDiscardsCount.value}',
                        color: colorScheme.error,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'LÍQUIDO DO DIA',
                        value: '${viewModel.dailyNetCount.value}',
                        color: colorScheme.primary,
                        isHighlight: true,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'CAIXAS FECHADAS',
                        value: '${viewModel.dailyCompletedBoxes.value}',
                        color: colorScheme.secondary,
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
    final products = viewModel.availableProducts.value;
    final activeBatch = viewModel.activeBatch.value;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SELECIONAR PRODUTO DO LOTE',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (activeBatch != null)
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.errorContainer,
                          foregroundColor: colorScheme.onErrorContainer,
                        ),
                        onPressed: () async {
                          await viewModel.finishActiveBatch();
                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                        },
                        icon: const Icon(Icons.stop_circle_outlined, size: 18),
                        label: const Text('Encerrar Lote Atual'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final product in products)
                      SizedBox(
                        width: 210,
                        child: Card(
                          color: activeBatch?.product.id == product.id
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: activeBatch?.product.id == product.id
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              await viewModel.startBatch(product);
                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${product.unitWeightGrams}g • Caixa: ${product.defaultBoxCapacity} un',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
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
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDiscardSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    AdjustmentReasonEnum selectedReason = AdjustmentReasonEnum.brokenShell;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'LANÇAR QUEBRA / DESCARTE',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final reason in AdjustmentReasonEnum.values)
                          ChoiceChip(
                            label: Text(reason.label),
                            selected: selectedReason == reason,
                            onSelected: (_) {
                              setState(() => selectedReason = reason);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (final qty in [1, 2, 5]) ...[
                          Expanded(
                            child: FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                backgroundColor: colorScheme.errorContainer,
                                foregroundColor: colorScheme.onErrorContainer,
                              ),
                              onPressed: () async {
                                await viewModel.addDiscards(
                                  reason: selectedReason,
                                  quantity: qty,
                                );
                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                              },
                              child: Text(
                                '-$qty ${qty == 1 ? "Ovo" : "Ovos"}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ),
                          if (qty != 5) const SizedBox(width: 10),
                        ],
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
}

final class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isHighlight;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: isHighlight ? FontWeight.w900 : FontWeight.bold,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
