import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_motion.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/app_states.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/status_badge.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/adjustment_reason_enum.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/product_model.dart';
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
              width: 1.5,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, cardConstraints) {
              final hasBoundedHeight = cardConstraints.maxHeight.isFinite;

              final heroCurrentBoxSection = Column(
                mainAxisSize:
                    hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            SlidingCounterText(
                              value: currentBox,
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontFamily: AppTheme.fontHeading,
                                fontWeight: FontWeight.w900,
                                fontSize: 96,
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
                              '/ $boxCap',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 26,
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
                  const SizedBox(height: 8),
                  SmoothProgressBar(
                    value: progress,
                    minHeight: 8,
                    progressColor: progress >= 1.0
                        ? AppTheme.successGreen
                        : colorScheme.primary,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    borderRadius: AppSpacing.borderRadiusXs,
                  ),
                ],
              );

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisSize:
                      hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
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
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: colorScheme.onErrorContainer,
                                    size: 18,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      'Esteira em movimento sem lote aberto! Toque para selecionar o produto.',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                      const SizedBox(height: 4),
                    ],

                    // --- Topo Super Clean: Produto + Status + Botão Discreto Encerrar Lote ---
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  viewModel.productName.value.toUpperCase(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontFamily: AppTheme.fontHeading,
                                    fontWeight: FontWeight.w900,
                                    fontSize: hasBatch ? 16 : 14,
                                    letterSpacing: 0.4,
                                    color: hasBatch
                                        ? colorScheme.onSurface
                                        : AppTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
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
                        ),
                        if (hasBatch)
                          InkWell(
                            borderRadius: AppSpacing.borderRadiusXs,
                            onTap: () => _showProductSelectorSheet(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.stop_circle_outlined,
                                    size: 13,
                                    color: AppTheme.textMuted.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'ENCERRAR LOTE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // --- 1º MAIS IMPORTANTE: Contagem Atual centralizada e limpa ---
                    if (hasBoundedHeight)
                      Expanded(child: heroCurrentBoxSection)
                    else
                      heroCurrentBoxSection,

                    const SizedBox(height: 8),

                    // --- 2º MAIS IMPORTANTE: Apenas Total e Caixas Fechadas limpos ---
                    Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            label: 'TOTAL',
                            value: '${viewModel.dailyNetCount.value}',
                            color: colorScheme.primary,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
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

                    const SizedBox(height: 8),

                    // --- Único Botão Operacional na Base ---
                    if (!hasBatch)
                      PressableScale(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSpacing.borderRadiusMd,
                            ),
                          ),
                          onPressed: () => _showProductSelectorSheet(context),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text(
                            'INICIAR LOTE DE PRODUÇÃO',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      )
                    else
                      PressableScale(
                        child: FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            foregroundColor: colorScheme.onSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSpacing.borderRadiusMd,
                              side: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                          onPressed: () => _showDiscardSheet(context),
                          icon: const Icon(
                            Icons.exposure_rounded,
                            size: 18,
                          ),
                          label: const Text(
                            'AJUSTAR CONTAGEM / QUEBRA',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showProductSelectorSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Dispara atualização em background ao abrir o seletor
    viewModel.refreshProducts();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 720),
      backgroundColor: colorScheme.surfaceContainerHigh,
      builder: (sheetCtx) {
        return _ProductSelectorBottomSheet(viewModel: viewModel);
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

final class _ProductSelectorBottomSheet extends StatefulWidget {
  final EggCountViewModel viewModel;

  const _ProductSelectorBottomSheet({required this.viewModel});

  @override
  State<_ProductSelectorBottomSheet> createState() =>
      _ProductSelectorBottomSheetState();
}

class _ProductSelectorBottomSheetState
    extends State<_ProductSelectorBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _filterProducts(List<ProductModel> all) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return all;
    return [
      for (final p in all)
        if (p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.eanCode.toLowerCase().contains(q) ||
            '${p.unitWeightGrams}g'.contains(q))
          p,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SignalBuilder(
      builder: (ctx) {
        final allProducts = widget.viewModel.availableProducts.value;
        final filteredProducts = _filterProducts(allProducts);
        final isSyncing = widget.viewModel.isSyncingProducts.value;
        final syncError = widget.viewModel.productsSyncError.value;
        final activeBatch = widget.viewModel.activeBatch.value;
        final isLocked = activeBatch != null;

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
                                : 'Produtos sincronizados do catálogo Supabase (sem mock)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('refresh_supabase_products_btn'),
                      tooltip: 'Sincronizar produtos do Supabase',
                      onPressed: isSyncing
                          ? null
                          : () => widget.viewModel.refreshProducts(),
                      icon: isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_rounded, size: 20),
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
                          await widget.viewModel.finishActiveBatch();
                          if (context.mounted) Navigator.pop(context);
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

                if (allProducts.length > 3) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const ValueKey('product_search_input'),
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar produto por nome, categoria ou gramas...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.clear_rounded, size: 16),
                            )
                          : null,
                      isDense: true,
                      filled: true,
                      fillColor: colorScheme.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                if (isSyncing && allProducts.isEmpty)
                  const AppLoadingState(
                    label: 'Buscando produtos ativos no Supabase...',
                  )
                else if (allProducts.isEmpty)
                  AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Nenhum produto sincronizado do Supabase',
                    subtitle:
                        syncError ??
                        'Verifique a conexão/login do Kiosk com o Supabase ou cadastre produtos ativos no ERP.',
                    action: FilledButton.tonalIcon(
                      onPressed: isSyncing
                          ? null
                          : () => widget.viewModel.refreshProducts(),
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Sincronizar Agora'),
                    ),
                  )
                else if (filteredProducts.isEmpty)
                  const AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Nenhum produto encontrado para a busca',
                    subtitle: 'Tente outro termo de pesquisa.',
                  )
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final product in filteredProducts)
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
                                            await widget.viewModel.startBatch(
                                              product,
                                            );
                                            if (context.mounted) {
                                              Navigator.pop(context);
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
                    'AJUSTAR CONTAGEM / DESCARTE',
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
            SignalBuilder(
              builder: (context) {
                final gross = widget.viewModel.dailyGrossCount.value;
                final discards = widget.viewModel.dailyDiscardsCount.value;
                final speed = widget.viewModel.eggsPerMinute.value;
                return Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        'Total Bruto: $gross',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        'Quebras/Desc.: $discards',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: discards > 0
                              ? colorScheme.error
                              : AppTheme.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        'Cadência: ${speed.toStringAsFixed(0)} ovos/min',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
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
                            : 'Qtd. a descontar (-)',
                        hintText: 'Ex: 5',
                        isDense: true,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 12,
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
                            color: actionColor,
                          ),
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
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: AppTheme.fontHeading,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              height: 1.05,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
