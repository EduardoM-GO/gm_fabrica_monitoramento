import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_motion.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/status_badge.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/ui/view_models/egg_count_view_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/ui/views/egg_adjustment_view.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/ui/views/product_selector_view.dart';
import 'package:signals/signals_flutter.dart';

final class EggCountCard extends StatelessWidget {
  final EggCountViewModel viewModel;

  const EggCountCard({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, cardConstraints) {
        final hasBoundedHeight = cardConstraints.maxHeight.isFinite;

        // Seção Hero da Caixa Atual: cada campo (Contador, Capacidade e Barra de Progresso)
        // possui seu próprio SignalBuilder (micro-state).
        final heroCurrentBoxSection = Column(
          mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
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
                      // Micro-state 1: Apenas o número da caixa atual (com flash verde ao registrar ovo)
                      SignalBuilder(
                        builder: (context) {
                          final currentBox = viewModel.currentBoxCount.value;
                          final active = viewModel.hasActiveBatch.value;
                          final isFlashing = viewModel.isHitAnimating.value;
                          return SlidingCounterText(
                            value: currentBox,
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontFamily: AppTheme.fontHeading,
                              fontWeight: FontWeight.w900,
                              fontSize: 96,
                              height: 1.0,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: isFlashing
                                  ? AppTheme.successGreen
                                  : (active
                                        ? colorScheme.primary
                                        : AppTheme.textMuted),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      // Micro-state 2: Capacidade da caixa (só muda quando troca de produto)
                      SignalBuilder(
                        builder: (context) {
                          final boxCap = viewModel.defaultBoxCapacity.value;
                          return Text(
                            '/ $boxCap',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 26,
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
            ),
            // Micro-state 2.5: Selo de confirmação do último ovo contado ("✓ +1 CONTADO • AGORA (23 → 24)")
            SignalBuilder(
              builder: (context) {
                final text = viewModel.lastHitConfirmationText.value;
                if (text == null) {
                  return const SizedBox(height: 6);
                }
                final isVibrant = viewModel.isRecentHitHighlight.value;
                final fgColor = isVibrant
                    ? AppTheme.successGreen
                    : AppTheme.textSecondary;
                final bgColor = isVibrant
                    ? AppTheme.successGreen.withValues(alpha: 0.20)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.65,
                      );
                final borderColor = isVibrant
                    ? AppTheme.successGreen.withValues(alpha: 0.65)
                    : colorScheme.outlineVariant;

                return Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 6),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AnimatedContainer(
                        key: const ValueKey('egg_last_hit_confirmation_badge'),
                        duration: AppMotion.durationFast,
                        curve: AppMotion.easeOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: AppSpacing.borderRadiusSm,
                          border: Border.all(
                            color: borderColor,
                            width: isVibrant ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVibrant
                                  ? Icons.check_circle_rounded
                                  : Icons.history_rounded,
                              size: 13,
                              color: fgColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              text,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight: isVibrant
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                letterSpacing: 0.3,
                                color: fgColor,
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
                );
              },
            ),
            // Micro-state 3: Barra de progresso da caixa
            SignalBuilder(
              builder: (context) {
                final progress = viewModel.boxProgress.value;
                return SmoothProgressBar(
                  value: progress,
                  minHeight: 8,
                  progressColor: progress >= 1.0
                      ? AppTheme.successGreen
                      : colorScheme.primary,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  borderRadius: AppSpacing.borderRadiusXs,
                );
              },
            ),
          ],
        );

        final cardBody = Padding(
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
              // --- Micro-state: Alerta de Esteira Rodando Sem Lote Ativo ---
              SignalBuilder(
                builder: (context) {
                  final isConveyorAlert =
                      viewModel.isConveyorRunningWithoutBatch.value;
                  if (!isConveyorAlert) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: BreathingGlow(
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
                              vertical: 6,
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
                  );
                },
              ),

              // --- Topo Super Clean: Produto + Status + Botão Encerrar Lote ---
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Micro-state: Nome do Produto
                        Flexible(
                          child: SignalBuilder(
                            builder: (context) {
                              final prodName = viewModel.productName.value
                                  .toUpperCase();
                              final active = viewModel.hasActiveBatch.value;
                              return Text(
                                prodName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontFamily: AppTheme.fontHeading,
                                  fontWeight: FontWeight.w900,
                                  fontSize: active ? 16 : 14,
                                  letterSpacing: 0.4,
                                  color: active
                                      ? colorScheme.onSurface
                                      : AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Micro-state: StatusBadge do lote (só muda quando abre/fecha lote)
                        SignalBuilder(
                          builder: (context) {
                            final active = viewModel.hasActiveBatch.value;
                            return StatusBadge(
                              label: active ? 'LOTE ATIVO' : 'EM REPOUSO',
                              color: active
                                  ? AppTheme.successGreen
                                  : AppTheme.textMuted,
                              compact: true,
                              subtle: !active,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Micro-state: Botão Trocar Produto / Gerenciar Lote (só reconstrói quando `hasActiveBatch` muda)
                  SignalBuilder(
                    builder: (context) {
                      final hasBatch = viewModel.hasActiveBatch.value;
                      if (!hasBatch) return const SizedBox.shrink();
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const ValueKey('manage_active_batch_btn'),
                          borderRadius: AppSpacing.borderRadiusXs,
                          onTap: () => _showProductSelectorSheet(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 14,
                                  color: AppTheme.textMuted.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'TROCAR / LOTE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10.5,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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

              // --- 2º MAIS IMPORTANTE: Total e Caixas Fechadas com Micro-States separados ---
              Row(
                children: [
                  Expanded(
                    child: SignalBuilder(
                      builder: (context) {
                        return _StatItem(
                          label: 'TOTAL',
                          value: '${viewModel.dailyNetCount.value}',
                          color: colorScheme.primary,
                        );
                      },
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  Expanded(
                    child: SignalBuilder(
                      builder: (context) {
                        return _StatItem(
                          label: 'CAIXAS FECHADAS',
                          value: '${viewModel.dailyCompletedBoxes.value}',
                          color: colorScheme.secondary,
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // --- Micro-state: Único Botão Operacional na Base (só reconstrói quando `hasActiveBatch` muda) ---
              SignalBuilder(
                builder: (context) {
                  final hasBatch = viewModel.hasActiveBatch.value;
                  if (!hasBatch) {
                    return PressableScale(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(42),
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
                    );
                  }
                  return PressableScale(
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(42),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        foregroundColor: colorScheme.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
                      onPressed: () => _showDiscardSheet(context),
                      icon: const Icon(Icons.exposure_rounded, size: 18),
                      label: const Text(
                        'AJUSTAR CONTAGEM / QUEBRA',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );

        // Micro-state da casca do Card: só reconstrói quando `isConveyorRunningWithoutBatch` ou `isHitAnimating` mudam,
        // mantendo `cardBody` intacto.
        return SignalBuilder(
          builder: (context) {
            final isConveyorAlert =
                viewModel.isConveyorRunningWithoutBatch.value;
            final isHitFlashing = viewModel.isHitAnimating.value;
            final Color cardColor;
            final Color borderColor;
            final double borderWidth;

            if (isConveyorAlert) {
              cardColor = colorScheme.errorContainer.withValues(alpha: 0.28);
              borderColor = colorScheme.error;
              borderWidth = 1.8;
            } else if (isHitFlashing) {
              cardColor = AppTheme.successGreen.withValues(alpha: 0.12);
              borderColor = AppTheme.successGreen;
              borderWidth = 2.2;
            } else {
              cardColor = colorScheme.surfaceContainer;
              borderColor = colorScheme.outlineVariant;
              borderWidth = 1.5;
            }

            return Card.outlined(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusXl,
                side: BorderSide(
                  color: borderColor,
                  width: borderWidth,
                ),
              ),
              child: cardBody,
            );
          },
        );
      },
    );
  }

  void _showProductSelectorSheet(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProductSelectorView(viewModel: viewModel),
      ),
    );
  }

  void _showDiscardSheet(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EggAdjustmentView(viewModel: viewModel),
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
