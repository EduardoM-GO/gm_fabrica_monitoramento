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
  static const String _eggFilterKey = '__eggs__';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory = _eggFilterKey;
  bool _forceCarryOverPrompt = false;

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

  bool _isEggCategoryName(String cat) {
    final lower = cat.trim().toLowerCase();
    return lower == 'ovo' || lower == 'ovos' || lower.contains('ovo');
  }

  List<String> _extractNonEggCategories(List<ProductModel> all) {
    final set = <String>{};
    for (final p in all) {
      final cat = p.category.trim();
      if (cat.isNotEmpty && !_isEggCategoryName(cat)) {
        set.add(cat);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  List<ProductModel> _filterProducts(List<ProductModel> all) {
    final q = _searchQuery.trim().toLowerCase();
    final hasAnyEggs = all.any((p) => p.isEgg);
    final effectiveCategory =
        (_selectedCategory == _eggFilterKey && !hasAnyEggs)
        ? null
        : _selectedCategory;

    final filtered = <ProductModel>[
      for (final p in all)
        if ((effectiveCategory == null ||
                (effectiveCategory == _eggFilterKey
                    ? p.isEgg
                    : p.category.toLowerCase() ==
                          effectiveCategory.toLowerCase())) &&
            (q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q) ||
                p.eanCode.toLowerCase().contains(q) ||
                '${p.unitWeightGrams}g'.contains(q)))
          p,
    ];

    // Ordena priorizando Ovos no topo e depois ordem alfabética
    filtered.sort((a, b) {
      if (a.isEgg != b.isEgg) {
        return a.isEgg ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return filtered;
  }

  Future<void> _confirmAndCloseBatch(BuildContext context) async {
    final activeBatch = widget.viewModel.activeBatch.value;
    if (activeBatch == null) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: colorScheme.error,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Encerrar Produção do Dia?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'A produção de "${activeBatch.product.name}" permanece aberta automaticamente até o final do dia (00:00).\n\nDeseja realmente encerrar o lote atual agora ou prefere apenas selecionar outro produto?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Manter Produção Aberta'),
          ),
          FilledButton.tonalIcon(
            key: const ValueKey('confirm_finish_active_batch_btn'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.stop_circle_outlined, size: 18),
            label: const Text(
              'Confirmar Encerramento',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await widget.viewModel.finishActiveBatch();
      if (context.mounted) Navigator.pop(context);
    }
  }

  /// Pergunta ao operador se deseja continuar a última caixa aberta (ex: 23 un. do lote anterior -> faltam 27)
  /// ou começar uma caixa nova do zero (0 / 50).
  /// Retorna `null` se o operador cancelar o diálogo, `0` para caixa nova ou `> 0` para continuar caixa aberta.
  Future<int?> _promptCarryOverUnitsDialog(
    BuildContext context, {
    required ProductModel product,
    required int suggestedCarryOver,
    String? sourceProductName,
  }) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final boxCap = product.defaultBoxCapacity > 0
        ? product.defaultBoxCapacity
        : 50;
    int selectedCarry = suggestedCarryOver > 0
        ? suggestedCarryOver.clamp(1, boxCap - 1)
        : (boxCap ~/ 2);

    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final remainingForFirst = (boxCap - selectedCarry).clamp(
              1,
              boxCap - 1,
            );
            return AlertDialog(
              key: const ValueKey('carry_over_box_dialog'),
              backgroundColor: colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusLg,
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    color: AppTheme.cocoaGold,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Continuar Última Caixa Aberta?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      suggestedCarryOver > 0
                          ? 'A última caixa de ${sourceProductName ?? product.name} terminou com $suggestedCarryOver un. (capacidade: $boxCap un.).'
                          : 'Informe quantos ovos da produção anterior já estão na caixa aberta (capacidade: $boxCap un.):',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(
                          color: AppTheme.cocoaGold.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton.filledTonal(
                                key: const ValueKey('carry_over_dec_btn'),
                                onPressed: selectedCarry > 1
                                    ? () => setDialogState(
                                        () => selectedCarry -= 1,
                                      )
                                    : null,
                                icon: const Icon(Icons.remove_rounded),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Column(
                                children: [
                                  Text(
                                    '$selectedCarry un. na caixa',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontFamily: AppTheme.fontHeading,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.cocoaGold,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '1ª caixa fecha com +$remainingForFirst ovos (0 / $remainingForFirst)',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onSurfaceVariant,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: AppSpacing.md),
                              IconButton.filledTonal(
                                key: const ValueKey('carry_over_inc_btn'),
                                onPressed: selectedCarry < boxCap - 1
                                    ? () => setDialogState(
                                        () => selectedCarry += 1,
                                      )
                                    : null,
                                icon: const Icon(Icons.add_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• O contador TOTAL do dia começará em 0 (contando apenas os ovos produzidos hoje).\n• Após fechar essa 1ª caixa (+$remainingForFirst un.), as próximas voltam para 0 / $boxCap.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: const Text('Cancelar'),
                ),
                OutlinedButton(
                  key: const ValueKey('start_fresh_box_btn'),
                  onPressed: () => Navigator.pop(dialogContext, 0),
                  child: Text(
                    'Caixa Nova (0 / $boxCap)',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.icon(
                  key: const ValueKey('confirm_carry_over_box_btn'),
                  onPressed: () => Navigator.pop(dialogContext, selectedCarry),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text(
                    'Continuar Caixa (0 / $remainingForFirst)',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndSwitchProduct(
    BuildContext context,
    ProductModel newProduct,
  ) async {
    final activeBatch = widget.viewModel.activeBatch.value;
    final boxCap = newProduct.defaultBoxCapacity > 0
        ? newProduct.defaultBoxCapacity
        : 50;

    if (activeBatch == null) {
      int carryOver = 0;
      final remRes = await widget.viewModel.getLastOpenBoxRemainder(
        productId: newProduct.id,
        targetBoxCapacity: boxCap,
      );
      final detectedCarry = remRes.valueOrNull?.carryOverUnits ?? 0;
      final sourceName = remRes.valueOrNull?.sourceProductName;

      if ((detectedCarry > 0 || _forceCarryOverPrompt) && context.mounted) {
        final chosen = await _promptCarryOverUnitsDialog(
          context,
          product: newProduct,
          suggestedCarryOver: detectedCarry,
          sourceProductName: sourceName,
        );
        if (chosen == null || !context.mounted) return;
        carryOver = chosen;
      }

      await widget.viewModel.startBatch(
        newProduct,
        carryOverUnits: carryOver,
      );
      if (context.mounted) Navigator.pop(context);
      return;
    }

    if (activeBatch.product.id == newProduct.id) {
      if (context.mounted) Navigator.pop(context);
      return;
    }

    // Se o lote atual tem uma caixa incompleta (ou se havia sobra anterior deste novo produto),
    // calcula a sugestão de sobra para oferecer no modal de troca
    final currentBoxOpenUnits = widget.viewModel.currentBoxCount.value;
    final currentCarry = widget.viewModel.carryOverUnits.value;
    final currentPhysicalInBox = widget.viewModel.isCompletingCarryOverBox.value
        ? (currentCarry + currentBoxOpenUnits)
        : currentBoxOpenUnits;

    final remRes = await widget.viewModel.getLastOpenBoxRemainder(
      productId: newProduct.id,
      targetBoxCapacity: boxCap,
    );
    final pastProductCarry = remRes.valueOrNull?.carryOverUnits ?? 0;
    final suggestedCarry = currentPhysicalInBox > 0 &&
            currentPhysicalInBox < boxCap
        ? currentPhysicalInBox
        : pastProductCarry;

    if (!context.mounted) return;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        title: Row(
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Trocar Produto em Produção?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Produto atual: ${activeBatch.product.name}\nNovo produto: ${newProduct.name} (${newProduct.unitWeightGrams}g • Caixa: ${newProduct.defaultBoxCapacity} un)\n\nO lote anterior será salvo com a contagem atual e a produção continuará aberta até o final do dia com o novo produto.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            key: const ValueKey('confirm_switch_product_btn'),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text(
              'Confirmar Troca de Produto',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      int carryOver = 0;
      if ((suggestedCarry > 0 || _forceCarryOverPrompt) && context.mounted) {
        final chosen = await _promptCarryOverUnitsDialog(
          context,
          product: newProduct,
          suggestedCarryOver: suggestedCarry,
          sourceProductName: currentPhysicalInBox > 0
              ? activeBatch.product.name
              : remRes.valueOrNull?.sourceProductName,
        );
        if (chosen == null || !context.mounted) return;
        carryOver = chosen;
      }

      await widget.viewModel.switchProduct(
        newProduct,
        carryOverUnits: carryOver,
      );
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = AppBreakpoints.isTabletKiosk(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        top: false,
        bottom: false,
        child: SignalBuilder(
          builder: (context) {
            final allProducts = widget.viewModel.availableProducts.value;
            final hasAnyEggs = allProducts.any((p) => p.isEgg);
            final nonEggCategories = _extractNonEggCategories(allProducts);
            final filteredProducts = _filterProducts(allProducts);
            final isSyncing = widget.viewModel.isSyncingProducts.value;
            final syncError = widget.viewModel.productsSyncError.value;
            final activeBatch = widget.viewModel.activeBatch.value;
            final isLocked = activeBatch != null;
            final effectiveCategory =
                (_selectedCategory == _eggFilterKey && !hasAnyEggs)
                ? null
                : _selectedCategory;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? AppSpacing.md : AppSpacing.sm,
                vertical: isTablet ? AppSpacing.xs : 6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KioskSubpageHeader(
                    title: isLocked
                        ? 'LOTE EM ANDAMENTO'
                        : 'SELECIONAR PRODUTO DO LOTE',
                    subtitle: isLocked
                        ? 'A produção permanece aberta até o final do dia (00:00). Toque em outro produto para trocar.'
                        : 'Filtrado primeiramente por Ovos • Produção permanece ativa até o final do dia',
                    icon: isLocked
                        ? Icons.inventory_rounded
                        : Icons.play_circle_fill_rounded,
                    eggViewModel: widget.viewModel,
                    backLabel: 'Voltar',
                    actions: [
                      IconButton(
                        key: const ValueKey('refresh_supabase_products_btn'),
                        visualDensity: isTablet
                            ? VisualDensity.standard
                            : VisualDensity.compact,
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
                            : Icon(
                                Icons.sync_rounded,
                                size: isTablet ? 22 : 18,
                              ),
                      ),
                      if (isLocked)
                        FilledButton.tonalIcon(
                          key: const ValueKey('finish_active_batch_btn'),
                          style: FilledButton.styleFrom(
                            visualDensity: isTablet
                                ? VisualDensity.standard
                                : VisualDensity.compact,
                            minimumSize: Size(0, isTablet ? 44 : 36),
                            backgroundColor: colorScheme.errorContainer,
                            foregroundColor: colorScheme.onErrorContainer,
                          ),
                          onPressed: () => _confirmAndCloseBatch(context),
                          icon: Icon(
                            Icons.stop_circle_outlined,
                            size: isTablet ? 18 : 16,
                          ),
                          label: Text(
                            'Encerrar Lote Atual',
                            style: TextStyle(
                              fontSize: isTablet ? 13.5 : 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: isTablet ? AppSpacing.sm : 6),

                  // Banner de Lote Ativo (quando houver lote aberto)
                  if (isLocked) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? AppSpacing.md : AppSpacing.sm,
                        vertical: isTablet ? 10 : 8,
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
                            Icons.verified_rounded,
                            size: isTablet ? 22 : 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Ativo hoje até 23:59: ${activeBatch.product.name} (${activeBatch.product.unitWeightGrams}g • Caixa: ${activeBatch.product.defaultBoxCapacity} un)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: isTablet ? 13.5 : null,
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
                            compact: !isTablet,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isTablet ? AppSpacing.sm : 6),
                  ],

                  // Barra de Busca + Chips de Categoria (Ovos selecionado por padrão em 1º lugar)
                  if (allProducts.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: SizedBox(
                            height: isTablet ? 44 : 36,
                            child: TextField(
                              key: const ValueKey('product_search_input'),
                              controller: _searchController,
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                              style: TextStyle(fontSize: isTablet ? 14 : 12.5),
                              decoration: InputDecoration(
                                hintText:
                                    'Buscar ovo ou produto por nome, categoria ou gramas...',
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  size: isTablet ? 20 : 16,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                        icon: Icon(
                                          Icons.clear_rounded,
                                          size: isTablet ? 18 : 15,
                                        ),
                                      )
                                    : null,
                                isDense: !isTablet,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 10,
                                  vertical: isTablet ? 10 : 8,
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
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 5,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (hasAnyEggs) ...[
                                  FilterChip(
                                    key: const ValueKey('filter_chip_ovos'),
                                    label: Text(
                                      'OVOS',
                                      style: TextStyle(
                                        fontSize: isTablet ? 12.5 : 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    selected:
                                        effectiveCategory == _eggFilterKey,
                                    visualDensity: isTablet
                                        ? VisualDensity.standard
                                        : VisualDensity.compact,
                                    onSelected: (_) => setState(
                                      () => _selectedCategory = _eggFilterKey,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                FilterChip(
                                  key: const ValueKey('filter_chip_todos'),
                                  label: Text(
                                    'Todos',
                                    style: TextStyle(
                                      fontSize: isTablet ? 12.5 : 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  selected: effectiveCategory == null,
                                  visualDensity: isTablet
                                      ? VisualDensity.standard
                                      : VisualDensity.compact,
                                  onSelected: (_) => setState(
                                    () => _selectedCategory = null,
                                  ),
                                ),
                                for (final cat in nonEggCategories) ...[
                                  const SizedBox(width: 6),
                                  FilterChip(
                                    key: ValueKey('filter_chip_$cat'),
                                    label: Text(
                                      cat.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: isTablet ? 12.5 : 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    selected: effectiveCategory == cat,
                                    visualDensity: isTablet
                                        ? VisualDensity.standard
                                        : VisualDensity.compact,
                                    onSelected: (sel) => setState(
                                      () => _selectedCategory = sel
                                          ? cat
                                          : (hasAnyEggs ? _eggFilterKey : null),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 6),
                                FilterChip(
                                  key: const ValueKey(
                                    'toggle_continue_open_box_chip',
                                  ),
                                  selected: _forceCarryOverPrompt,
                                  visualDensity: isTablet
                                      ? VisualDensity.standard
                                      : VisualDensity.compact,
                                  avatar: Icon(
                                    Icons.inventory_2_outlined,
                                    size: isTablet ? 18 : 15,
                                    color: _forceCarryOverPrompt
                                        ? AppTheme.cocoaGold
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  label: Text(
                                    'Continuar Caixa Aberta',
                                    style: TextStyle(
                                      fontSize: isTablet ? 12.5 : 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  onSelected: (val) => setState(
                                    () => _forceCarryOverPrompt = val,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? AppSpacing.sm : 6),
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
                                    mainAxisSpacing:
                                        isTablet ? AppSpacing.sm : AppSpacing.xs,
                                    crossAxisSpacing:
                                        isTablet ? AppSpacing.sm : AppSpacing.xs,
                                    mainAxisExtent: isTablet ? 108 : 86,
                                  ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                final isCurrent =
                                    activeBatch?.product.id == product.id;

                                return Card.outlined(
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
                                    onTap: () => _confirmAndSwitchProduct(
                                      context,
                                      product,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet
                                            ? AppSpacing.md
                                            : AppSpacing.sm,
                                        vertical: isTablet ? 12 : 8,
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
                                                        fontSize: isTablet
                                                            ? 15
                                                            : 13,
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
                                                  size: isTablet ? 20 : 16,
                                                  color: colorScheme.primary,
                                                )
                                              else if (isLocked)
                                                Icon(
                                                  Icons.swap_horiz_rounded,
                                                  size: isTablet ? 20 : 16,
                                                  color: colorScheme.primary,
                                                )
                                              else
                                                Icon(
                                                  Icons
                                                      .play_circle_outline_rounded,
                                                  size: isTablet ? 20 : 16,
                                                  color: colorScheme.primary,
                                                ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
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
                                                        fontSize: isTablet
                                                            ? 13
                                                            : null,
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
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: isTablet ? 8 : 6,
                                                  vertical: isTablet ? 4 : 2,
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
                                                    fontSize:
                                                        isTablet ? 11 : 9.5,
                                                    fontWeight: FontWeight.w800,
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
