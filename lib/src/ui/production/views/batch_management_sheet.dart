import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/entities/batch_adjustment_entity.dart';
import '../../../core/themes/app_theme.dart';
import '../view_models/production_viewmodel.dart';

/// Bottom sheet dialog for starting, pausing, finishing batches,
/// and recording breakages/adjustments.
class BatchManagementBottomSheet extends StatefulWidget {
  const BatchManagementBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    final prodVm = context.read<ProductionViewModel>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider<ProductionViewModel>.value(
        value: prodVm,
        child: const BatchManagementBottomSheet(),
      ),
    );
  }

  @override
  State<BatchManagementBottomSheet> createState() =>
      _BatchManagementBottomSheetState();
}

class _BatchManagementBottomSheetState
    extends State<BatchManagementBottomSheet> {
  String? _selectedProductId;
  AdjustmentReason _selectedReason = AdjustmentReason.brokenShell;
  int _discardQty = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewModel = context.watch<ProductionViewModel>();
    final state = viewModel.state;
    final activeBatch = state.activeBatch;
    final hasActiveBatch =
        activeBatch != null && !activeBatch.status.isCompleted;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Title bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_rounded,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Gestão de Lote de Produção',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 16),

            if (hasActiveBatch) ...[
              _buildActiveBatchCard(context, activeBatch),
              const SizedBox(height: 16),
              _buildDiscardSection(context, activeBatch),
            ] else ...[
              _buildNewBatchSection(context, state),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBatchCard(
    BuildContext context,
    ProductionBatchEntity batch,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewModel = context.read<ProductionViewModel>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.productName.toUpperCase(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${batch.unitWeightGrams.toStringAsFixed(0)}g por unidade',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: batch.status.isInProgress
                      ? AppTheme.successGreen.withValues(alpha: 0.15)
                      : AppTheme.warningAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: batch.status.isInProgress
                        ? AppTheme.successGreen
                        : AppTheme.warningAmber,
                  ),
                ),
                child: Text(
                  batch.status.isInProgress ? 'EM ANDAMENTO' : 'PAUSADO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: batch.status.isInProgress
                        ? AppTheme.successGreen
                        : AppTheme.warningAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Bruto Contado',
                  value: '${batch.grossProducedCount}',
                  color: colorScheme.onSurface,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  label: 'Descartes',
                  value: '${batch.discardedCount}',
                  color: AppTheme.dangerRed,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  label: 'Líquido Aprovado',
                  value: '${batch.netProducedCount}',
                  color: AppTheme.successGreen,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  label: 'Massa Total',
                  value: '${batch.totalWeightKg.toStringAsFixed(1)} kg',
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Batch Action Buttons
          Row(
            children: [
              if (batch.status.isInProgress)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.warningAmber,
                      side: const BorderSide(color: AppTheme.warningAmber),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.pause_rounded, size: 18),
                    label: const Text('Pausar Lote'),
                    onPressed: () => viewModel.pauseBatch(),
                  ),
                )
              else
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Retomar Lote'),
                    onPressed: () => viewModel.resumeBatch(),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.dangerRed.withValues(alpha: 0.15),
                    foregroundColor: AppTheme.dangerRed,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => _confirmFinishBatch(context, viewModel),
                  child: const Text('Finalizar Lote'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildDiscardSection(
    BuildContext context,
    ProductionBatchEntity batch,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewModel = context.read<ProductionViewModel>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.remove_circle_outline_rounded,
                color: AppTheme.dangerRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Lançar Quebra / Descarte',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Reason selector chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AdjustmentReason.values.map((reason) {
              final isSelected = _selectedReason == reason;
              return ChoiceChip(
                label: Text(
                  reason.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppTheme.dangerRed.withValues(alpha: 0.2),
                onSelected: (val) {
                  if (val) setState(() => _selectedReason = reason);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Quantity stepper and confirm button
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, size: 18),
                      onPressed: () {
                        if (_discardQty > 1) {
                          setState(() => _discardQty--);
                        }
                      },
                    ),
                    Text(
                      '$_discardQty',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      onPressed: () => setState(() => _discardQty++),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.dangerRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.save_alt_rounded, size: 18),
                  label: Text('Registrar -$_discardQty Ovo(s)'),
                  onPressed: () {
                    viewModel.registerAdjustment(
                      reason: _selectedReason,
                      quantity: _discardQty,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Registrado estorno de $_discardQty ovo(s) (${_selectedReason.displayName})',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    setState(() => _discardQty = 1);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewBatchSection(BuildContext context, ProductionState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewModel = context.read<ProductionViewModel>();
    final products = state.availableProducts;

    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Carregando produtos cadastrados...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    _selectedProductId ??= products.first.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Selecione o produto para iniciar o lote:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        ...products.map((prod) {
          final isSelected = _selectedProductId == prod.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _selectedProductId = prod.id),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${prod.unitWeightGrams.toStringAsFixed(0)}g | Caixa de ${prod.defaultBoxCapacity} ovos',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.successGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.play_circle_filled_rounded),
          label: const Text(
            'INICIAR NOVO LOTE',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          onPressed: () {
            if (_selectedProductId != null) {
              viewModel.startBatch(_selectedProductId!);
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }

  void _confirmFinishBatch(
    BuildContext context,
    ProductionViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar Lote?'),
        content: const Text(
          'Deseja realmente encerrar a contagem deste lote? '
          'Os totais serão arquivados e enviados para a nuvem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () {
              viewModel.finishBatch();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Confirmar e Finalizar'),
          ),
        ],
      ),
    );
  }
}
