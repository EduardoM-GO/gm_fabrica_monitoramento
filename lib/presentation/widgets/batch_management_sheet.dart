import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/batch_adjustment_entity.dart';
import '../../domain/entities/production_batch_entity.dart';
import '../../logic/production/production_cubit.dart';
import '../../logic/production/production_state.dart';

class BatchManagementBottomSheet extends StatefulWidget {
  const BatchManagementBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ProductionCubit>(),
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

    return BlocBuilder<ProductionCubit, ProductionState>(
      builder: (context, state) {
        final activeBatch = state.activeBatch;
        final hasActiveBatch = activeBatch != null && !activeBatch.status.isCompleted;

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
      },
    );
  }

  Widget _buildActiveBatchCard(
    BuildContext context,
    ProductionBatchEntity batch,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cubit = context.read<ProductionCubit>();

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
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(
                    batch.status.isInProgress
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 20,
                  ),
                  label: Text(
                    batch.status.isInProgress ? 'Pausar Lote' : 'Retomar Lote',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    if (batch.status.isInProgress) {
                      cubit.pauseBatch();
                    } else {
                      cubit.resumeBatch();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.dangerRed,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: const Text(
                    'Finalizar Lote',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  onPressed: () => _confirmFinishBatch(context, cubit),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
          ),
        ),
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
    final cubit = context.read<ProductionCubit>();

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
                Icons.report_problem_outlined,
                color: AppTheme.dangerRed,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Lançamento de Estorno / Descarte',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Motivos (Chips)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AdjustmentReason.values.map((reason) {
              final selected = _selectedReason == reason;
              return FilterChip(
                selected: selected,
                visualDensity: VisualDensity.compact,
                label: Text(
                  reason.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                onSelected: (_) => setState(() => _selectedReason = reason),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Stepper de Quantidade e Botão Confirmar
          Row(
            children: [
              Text(
                'Quantidade:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove, size: 18),
                onPressed: _discardQty > 1
                    ? () => setState(() => _discardQty--)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$_discardQty',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => setState(() => _discardQty++),
              ),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.dangerRed,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: const Text(
                  'Registrar Estorno',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                onPressed: () {
                  cubit.registerAdjustment(
                    reason: _selectedReason,
                    quantity: _discardQty,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Estorno de $_discardQty ovos registrado com sucesso.'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  setState(() => _discardQty = 1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewBatchSection(
    BuildContext context,
    ProductionState state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cubit = context.read<ProductionCubit>();
    final products = state.availableProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Nenhum lote em andamento. Selecione o produto para iniciar:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        for (final p in products) ...[
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _selectedProductId = p.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: (_selectedProductId ?? products.first.id) == p.id
                    ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_selectedProductId ?? products.first.id) == p.id
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: (_selectedProductId ?? products.first.id) == p.id ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    (_selectedProductId ?? products.first.id) == p.id
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: (_selectedProductId ?? products.first.id) == p.id
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        Text(
                          '${p.unitWeightGrams.toStringAsFixed(0)}g • Caixa padrão: ${p.defaultBoxCapacity} ovos',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),

        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.eggOrange,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.play_circle_filled_rounded, size: 24),
          label: const Text(
            'INICIAR NOVO LOTE',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          onPressed: () {
            final targetId = _selectedProductId ??
                (products.isNotEmpty ? products.first.id : null);
            if (targetId != null) {
              cubit.startBatch(targetId);
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }

  void _confirmFinishBatch(BuildContext context, ProductionCubit cubit) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Finalizar Lote de Produção?'),
        content: const Text(
          'Esta ação consolidará as métricas do lote e o marcará como concluído no banco de dados local.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () {
              cubit.finishBatch();
              Navigator.pop(dlgCtx);
              Navigator.pop(context);
            },
            child: const Text('Sim, Finalizar'),
          ),
        ],
      ),
    );
  }
}
