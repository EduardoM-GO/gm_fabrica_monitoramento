import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/themes/app_motion.dart';
import '../../../core/themes/app_theme.dart';
import '../../settings/view_models/settings_viewmodel.dart';
import '../../settings/views/settings_dialog.dart';
import '../view_models/production_viewmodel.dart';
import 'batch_management_sheet.dart';

/// Hero Card for packaging operators displaying real-time egg counts,
/// box progress, speed ticker, and batch controls.
/// Follows Material Design 3 and Flutter's official MVVM architecture.
class EggPackagingHeroCard extends StatelessWidget {
  const EggPackagingHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settingsViewModel = context.watch<SettingsViewModel>();
    final productionViewModel = context.watch<ProductionViewModel>();
    final settings = settingsViewModel.state;
    final state = productionViewModel.state;

    final isAnimating = state.isHitAnimating;
    final isBoxJustCompleted = state.isBoxJustCompleted;
    final count = state.currentBoxCount;
    final capacity = state.boxCapacity;
    final progress = capacity > 0 ? (count / capacity).clamp(0.0, 1.0) : 0.0;

    return Card(
      color: isBoxJustCompleted
          ? colorScheme.secondaryContainer.withValues(alpha: 0.35)
          : colorScheme.surfaceContainer,
      elevation: isAnimating ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isBoxJustCompleted
              ? AppTheme.successGreen
              : isAnimating
              ? AppTheme.eggOrange
              : colorScheme.outlineVariant,
          width: (isAnimating || isBoxJustCompleted) ? 2.5 : 1.2,
        ),
      ),
      child: AnimatedContainer(
        duration: AppMotion.durationStandard,
        curve: AppMotion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Header: Title, Speed & Audio toggle ---
            Row(
              children: [
                AnimatedScale(
                  scale: isAnimating ? 1.15 : 1.0,
                  duration: AppMotion.durationFast,
                  curve: AppMotion.easeOut,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.eggOrange.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isAnimating
                            ? AppTheme.eggOrange
                            : AppTheme.eggOrange.withValues(alpha: 0.4),
                        width: isAnimating ? 1.5 : 1.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.egg_alt_rounded,
                      color: AppTheme.eggOrange,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CONTAGEM DE OVOS',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.eggOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${state.eggsPerMinute.toStringAsFixed(0)} ovos/min',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Live status badge with smooth connection indicator
                _buildConnectionStatusBadge(context, state, settings),

                const SizedBox(width: 4),

                // Audio Mute/Unmute quick toggle with tactile micro-interaction
                PressableScale(
                  child: IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    tooltip: settings.eggSoundEnabled
                        ? 'Desativar feedback sonoro'
                        : 'Ativar feedback sonoro',
                    icon: Icon(
                      settings.eggSoundEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      size: 18,
                    ),
                    onPressed: () {
                      settingsViewModel.toggleEggSound(
                        !settings.eggSoundEnabled,
                      );
                    },
                  ),
                ),

                const SizedBox(width: 4),

                // Settings button with tactile micro-interaction
                PressableScale(
                  child: IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Configurações de Conexão e Alertas',
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const SettingsDialog(),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // --- Hero Counter Display (X / Capacity) with Smooth Rolling Counter ---
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedScale(
                          scale: isAnimating ? 1.05 : 1.0,
                          duration: AppMotion.durationFast,
                          curve: AppMotion.easeOut,
                          child: SlidingCounterText(
                            value: count,
                            duration: AppMotion.durationFast,
                            curve: AppMotion.easeOut,
                            style: TextStyle(
                              fontSize: 68,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              letterSpacing: -2,
                              color: isBoxJustCompleted
                                  ? AppTheme.successGreen
                                  : isAnimating
                                  ? AppTheme.eggOrange
                                  : colorScheme.onSurface,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '/ $capacity',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: AppMotion.durationStandard,
                      switchInCurve: AppMotion.easeOut,
                      switchOutCurve: AppMotion.easeOut,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: AppMotion.easeOut,
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: isBoxJustCompleted
                          ? Row(
                              key: const ValueKey('box_completed_banner'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.successGreen,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'CAIXA COMPLETA! INICIANDO PRÓXIMA...',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.successGreen,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'ovos na caixa atual',
                              key: const ValueKey('box_in_progress_label'),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // --- Liquid Smooth Animated Box Progress Bar ---
            SmoothProgressBar(
              value: progress,
              minHeight: 6,
              progressColor: isBoxJustCompleted
                  ? AppTheme.successGreen
                  : AppTheme.eggOrange,
              backgroundColor: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
              duration: AppMotion.durationStandard,
              curve: AppMotion.easeOut,
            ),

            const SizedBox(height: 6),

            // --- Ergonomic Controls: Responsive 2-Row Layout to guarantee no overflow ---
            // Row 1: Capacity selector + Reset Box
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    'Capacidade:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                  PressableScale(
                    child: FilterChip(
                      visualDensity: VisualDensity.compact,
                      selected: capacity == 40,
                      label: const Text('40'),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: capacity == 40
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      selectedColor: colorScheme.primary,
                      checkmarkColor: colorScheme.onPrimary,
                      onSelected: (_) {
                        productionViewModel.setBoxCapacity(40);
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  PressableScale(
                    child: FilterChip(
                      visualDensity: VisualDensity.compact,
                      selected: capacity == 50,
                      label: const Text('50'),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: capacity == 50
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      selectedColor: colorScheme.primary,
                      checkmarkColor: colorScheme.onPrimary,
                      onSelected: (_) {
                        productionViewModel.setBoxCapacity(50);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  PressableScale(
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Zerar caixa atual',
                      icon: Icon(
                        Icons.restart_alt_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        productionViewModel.resetCurrentBox();
                      },
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Chip de Gestão de Lote
                  PressableScale(
                    child: ActionChip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(
                        state.activeBatch != null
                            ? Icons.inventory_2_rounded
                            : Icons.add_circle_outline_rounded,
                        size: 15,
                        color: state.activeBatch != null
                            ? AppTheme.eggOrange
                            : colorScheme.primary,
                      ),
                      label: Text(
                        state.activeBatch != null
                            ? '${state.activeBatch!.productName} (${state.batchTotalWeightKg.toStringAsFixed(1)}kg)'
                            : 'Iniciar Lote',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: state.activeBatch != null
                              ? AppTheme.eggOrange
                              : colorScheme.onSurface,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      backgroundColor: state.activeBatch != null
                          ? AppTheme.eggOrange.withValues(alpha: 0.12)
                          : colorScheme.surfaceContainerHighest,
                      side: BorderSide(
                        color: state.activeBatch != null
                            ? AppTheme.eggOrange.withValues(alpha: 0.4)
                            : colorScheme.outlineVariant,
                      ),
                      onPressed: () {
                        BatchManagementBottomSheet.show(context);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Row 2: Large 48dp Touch Buttons for Manual Adjustment (-1 and +1)
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: PressableScale(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(0, 48),
                        side: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.remove_rounded, size: 22),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '-1 Ovo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      onPressed: () {
                        productionViewModel.decrementManual();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: PressableScale(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(0, 48),
                        backgroundColor: AppTheme.eggOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 22),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '+1 Ovo',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      onPressed: () {
                        productionViewModel.incrementManual();
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 4),

            // --- Discreet / Subtle Daily Total Footer (Responsive Wrap) ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      Text(
                        'TOTAL DIA: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${state.dailyTotalEggs} ovos',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        ' • ${state.completedBoxesCount} cx',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtle reset day button
                PressableScale(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () {
                      _showResetDayConfirmation(context, productionViewModel);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        'Zerar Dia',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.outline,
                          fontWeight: FontWeight.w500,
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

  void _showResetDayConfirmation(
    BuildContext context,
    ProductionViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Zerar Contagem do Dia?'),
        content: const Text(
          'Isso reiniciará o total de ovos do dia e a quantidade de caixas fechadas para zero. Esta ação é indicada ao iniciar um novo turno de trabalho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () {
              viewModel.resetDailyTotal();
              Navigator.pop(dialogCtx);
            },
            child: const Text('Sim, Zerar Dia'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusBadge(
    BuildContext context,
    ProductionState state,
    SettingsState settings,
  ) {
    final status = state.connectionStatus;
    final isConnected = status == ConnectionStatus.connected;
    final isReconnecting =
        status == ConnectionStatus.reconnecting ||
        status == ConnectionStatus.connecting;

    Color statusColor;
    String statusText;
    if (isConnected) {
      statusColor = AppTheme.successGreen;
      statusText = settings.isMockEnabled ? 'Simulador' : 'Online';
    } else if (isReconnecting) {
      statusColor = AppTheme.warningAmber;
      statusText = 'Conectando';
    } else {
      statusColor = AppTheme.dangerRed;
      statusText = 'Offline';
    }

    return Tooltip(
      message:
          state.connectionErrorMessage ??
          (isConnected
              ? 'Conectado a ${settings.wsUrl}'
              : 'Tentando conectar a ${settings.wsUrl}. Toque para configurar.'),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          showDialog(context: context, builder: (_) => const SettingsDialog());
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
