import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_breakpoints.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/app_states.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/kiosk_subpage_header.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/status_badge.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/product_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/ui/view_models/egg_count_view_model.dart';
import 'package:signals/signals_flutter.dart';

/// Tela completa para Seleção de Produto do Lote e Gerenciamento/Encerramento do Lote Ativo.
/// Substitui o antigo BottomSheet espremido por um painel de alta densidade em tela cheia.
final class ProductSelectorView extends StatefulWidget {
  final EggCountViewModel viewModel;

  const ProductSelectorView({super.key, required this.viewModel});

  @override
  State<ProductSelectorView> createState() => _ProductSelectorViewState();
}

class _ProductSelectorViewState extends State<ProductSelectorView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    widget.viewModel.refreshProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _extractCategories(List<ProductModel> all) {
    final set = <String>{};
    for (final p in all) {
      final cat = p.category.trim();
      if (cat.isNotEmpty) set.add(cat);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<ProductModel> _filterProducts(List<ProductModel> all) {
    final q = _searchQuery.trim().toLowerCase();
    return [
      for (final p in all)
        if ((_selectedCategory == null || p.category == _selectedCategory) &&
            (q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q) ||
                p.eanCode.toLowerCase().contains(q) ||
                '${p.unitWeightGrams}g'.contains(q)))
          p,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        top: false,
        bottom: false,
        child: SignalBuilder(
          builder: (context) {
            final allProducts = widget.viewModel.availableProducts.value;
            final categories = _extractCategories(allProducts);
            final filteredProducts = _filterProducts(allProducts);
            final isSyncing = widget.viewModel.isSyncingProducts.value;
            final syncError = widget.viewModel.productsSyncError.value;
            final activeBatch = widget.viewModel.activeBatch.value;
            final isLocked = activeBatch != null;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KioskSubpageHeader(
                    title: isLocked
                        ? 'LOTE EM ANDAMENTO'
                        : 'SELECIONAR PRODUTO DO LOTE',
                    subtitle: isLocked
                        ? 'Encerre o lote atual antes de iniciar outro produto na esteira'
                        : 'Produtos sincronizados do catálogo Supabase (sem mock)',
                    icon: isLocked
                        ? Icons.inventory_rounded
                        : Icons.play_circle_fill_rounded,
                    eggViewModel: widget.viewModel,
                    backLabel: 'Voltar',
                    actions: [
                      IconButton(
                        key: const ValueKey('refresh_supabase_products_btn'),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Sincronizar produtos do Supabase',
                        onPressed: isSyncing
                            ? null
                            : () => widget.viewModel.refreshProducts(),
                        icon: isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync_rounded, size: 18),
                      ),
                      if (isLocked)
                        FilledButton.tonalIcon(
                          key: const ValueKey('finish_active_batch_btn'),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            minimumSize: const Size(0, 36),
                            backgroundColor: colorScheme.errorContainer,
                            foregroundColor: colorScheme.onErrorContainer,
                          ),
                          onPressed: () async {
                            await widget.viewModel.finishActiveBatch();
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.stop_circle_outlined,
                            size: 16,
                          ),
                          label: const Text(
                            'Encerrar Lote Atual',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Banner de Lote Ativo (quando houver lote aberto)
                  if (isLocked) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.45,
                        ),
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(color: colorScheme.primary),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_clock_rounded,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Produto ativo na esteira: ${activeBatch.product.name} (${activeBatch.product.unitWeightGrams}g • Caixa: ${activeBatch.product.defaultBoxCapacity} un)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          StatusBadge(
                            label:
                                'Total: ${widget.viewModel.dailyNetCount.value} • Caixas: ${widget.viewModel.dailyCompletedBoxes.value}',
                            color: AppTheme.successGreen,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Barra de Busca + Chips de Categoria na mesma linha
                  if (allProducts.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: SizedBox(
                            height: 36,
                            child: TextField(
                              key: const ValueKey('product_search_input'),
                              controller: _searchController,
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                              style: const TextStyle(fontSize: 12.5),
                              decoration: InputDecoration(
                                hintText:
                                    'Buscar produto por nome, categoria ou gramas...',
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 16,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                        icon: const Icon(
                                          Icons.clear_rounded,
                                          size: 15,
                                        ),
                                      )
                                    : null,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainer,
                                border: OutlineInputBorder(
                                  borderRadius: AppSpacing.borderRadiusSm,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (categories.length > 1) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: 5,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  FilterChip(
                                    label: const Text(
                                      'Todos',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    selected: _selectedCategory == null,
                                    visualDensity: VisualDensity.compact,
                                    onSelected: (_) => setState(
                                      () => _selectedCategory = null,
                                    ),
                                  ),
                                  for (final cat in categories) ...[
                                    const SizedBox(width: 6),
                                    FilterChip(
                                      label: Text(
                                        cat.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      selected: _selectedCategory == cat,
                                      visualDensity: VisualDensity.compact,
                                      onSelected: (sel) => setState(
                                        () => _selectedCategory = sel
                                            ? cat
                                            : null,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Área principal: Grid de Produtos ocupando toda a largura
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (isSyncing && allProducts.isEmpty) {
                          return const Center(
                            child: AppLoadingState(
                              label: 'Buscando produtos ativos no Supabase...',
                            ),
                          );
                        }
                        if (allProducts.isEmpty) {
                          return Center(
                            child: AppEmptyState(
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
                            ),
                          );
                        }
                        if (filteredProducts.isEmpty) {
                          return const Center(
                            child: AppEmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'Nenhum produto encontrado para a busca',
                              subtitle: 'Tente outro termo de pesquisa.',
                            ),
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final cols =
                                constraints.maxWidth >= AppBreakpoints.mediumMax
                                ? 4
                                : (constraints.maxWidth >=
                                          AppBreakpoints.compactMax
                                      ? 3
                                      : 2);

                            return GridView.builder(
                              padding: const EdgeInsets.only(bottom: 4),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    mainAxisSpacing: AppSpacing.xs,
                                    crossAxisSpacing: AppSpacing.xs,
                                    mainAxisExtent: 86,
                                  ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                final isCurrent =
                                    activeBatch?.product.id == product.id;

                                return Opacity(
                                  opacity: (!isLocked || isCurrent)
                                      ? 1.0
                                      : 0.45,
                                  child: Card.outlined(
                                    margin: EdgeInsets.zero,
                                    color: isCurrent
                                        ? colorScheme.primaryContainer
                                        : colorScheme.surfaceContainerHighest,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppSpacing.borderRadiusMd,
                                      side: BorderSide(
                                        color: isCurrent
                                            ? colorScheme.primary
                                            : colorScheme.outlineVariant,
                                        width: isCurrent ? 2.0 : 1.0,
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: 8,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
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
                                                              FontWeight.w900,
                                                          fontSize: 13,
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
                                                  )
                                                else
                                                  Icon(
                                                    Icons
                                                        .play_circle_outline_rounded,
                                                    size: 16,
                                                    color: colorScheme.primary,
                                                  ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    '${product.unitWeightGrams}g • Caixa: ${product.defaultBoxCapacity} un',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: isCurrent
                                                              ? colorScheme
                                                                    .onPrimaryContainer
                                                                    .withValues(
                                                                      alpha: 0.9,
                                                                    )
                                                              : colorScheme
                                                                    .onSurfaceVariant,
                                                          fontFeatures: const [
                                                            FontFeature.tabularFigures(),
                                                          ],
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme
                                                        .surfaceContainer,
                                                    borderRadius: AppSpacing
                                                        .borderRadiusXs,
                                                  ),
                                                  child: Text(
                                                    product.category
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
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
}
