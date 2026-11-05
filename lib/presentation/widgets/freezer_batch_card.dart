import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_formatter.dart';
import '../../data/models/freezer_view_data.dart';
import '../../logic/freezer/freezer_cubit.dart';

class FreezerBatchCard extends StatelessWidget {
  final FreezerViewData freezer;
  final int freezerNumber;

  const FreezerBatchCard({
    super.key,
    required this.freezer,
    required this.freezerNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isOpen = freezer.isDoorOpen;
    final isProbeOk = freezer.isProbeOk;
    final isReady = freezer.batchStatus == FreezerBatchStatus.ready;
    final isFeedback =
        freezer.batchStatus == FreezerBatchStatus.feedbackPending;

    // Determine state card styling (high contrast for 4m room visibility)
    Color cardBgColor;
    Color borderColor;
    Color accentColor;

    if (!isProbeOk) {
      cardBgColor = AppTheme.dangerRed.withValues(alpha: 0.15);
      borderColor = AppTheme.dangerRed;
      accentColor = AppTheme.dangerRed;
    } else if (isOpen) {
      cardBgColor = AppTheme.dangerRed.withValues(alpha: 0.18);
      borderColor = AppTheme.dangerRed;
      accentColor = AppTheme.dangerRed;
    } else if (isReady) {
      cardBgColor = AppTheme.successGreen.withValues(alpha: 0.22);
      borderColor = AppTheme.successGreen;
      accentColor = AppTheme.successGreen;
    } else if (isFeedback) {
      cardBgColor = AppTheme.warningAmber.withValues(alpha: 0.18);
      borderColor = AppTheme.warningAmber;
      accentColor = AppTheme.warningAmber;
    } else {
      // Normal cooling state
      cardBgColor = colorScheme.surfaceContainer;
      borderColor = colorScheme.outlineVariant;
      accentColor = colorScheme.primary;
    }

    return Card(
      color: cardBgColor,
      elevation: isReady ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor,
          width: (isReady || isOpen || !isProbeOk) ? 2.5 : 1.2,
        ),
      ),
      child: AnimatedContainer(
        duration: AppMotion.durationStandard,
        curve: AppMotion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Row 1: Header (Name, Probe chip, Temperature) ---
            Row(
              children: [
                Icon(Icons.ac_unit_rounded, color: accentColor, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        freezer.name.toUpperCase(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          fontSize: 12,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        freezerNumber == 1 ? 'Câmara' : 'Congelamento',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                // Large Temperature Readout
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isProbeOk
                        ? '${freezer.currentTemp.toStringAsFixed(1)} °C'
                        : '--.- °C',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isProbeOk
                          ? colorScheme.onSurface
                          : AppTheme.dangerRed,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // --- Row 2: Main Batch / Door / Feedback Status Banner with AnimatedSwitcher ---
            AnimatedSwitcher(
              duration: AppMotion.durationStandard,
              switchInCurve: AppMotion.easeOut,
              switchOutCurve: AppMotion.easeOut,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: AppMotion.easeOut,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
              child: isFeedback
                  ? KeyedSubtree(
                      key: const ValueKey('banner_feedback'),
                      child: _buildFeedbackPrompt(context, theme),
                    )
                  : isOpen
                      ? KeyedSubtree(
                          key: const ValueKey('banner_door_open'),
                          child: _buildDoorOpenBanner(theme),
                        )
                      : isReady
                          ? KeyedSubtree(
                              key: const ValueKey('banner_ready'),
                              child: _buildReadyBanner(context, theme),
                            )
                          : KeyedSubtree(
                              key: const ValueKey('banner_cooling'),
                              child: _buildCoolingBanner(context, theme, accentColor),
                            ),
            ),

            const SizedBox(height: 6),

            // --- Row 3: Mini footer (Delta & Simulator quick tools) ---
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOpen
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 12,
                      color: isOpen ? AppTheme.dangerRed : colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOpen
                          ? 'Perda: ${TimeFormatter.formatTemperatureDelta(freezer.temperatureDelta)}'
                          : 'Delta: ${TimeFormatter.formatTemperatureDelta(freezer.temperatureDelta)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isOpen
                            ? AppTheme.dangerRed
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                PressableScale(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () {
                      context.read<FreezerCubit>().toggleSimulatorDoor(
                        freezerNumber,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      child: Text(
                        isOpen ? 'Fechar Porta' : 'Abrir Porta',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOpen
                              ? AppTheme.successGreen
                              : AppTheme.warningAmber,
                        ),
                      ),
                    ),
                  ),
                ),
                PressableScale(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () {
                      context.read<FreezerCubit>().startFreezerBatch(
                        freezer.id,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      child: Text(
                        'Reiniciar',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.outline,
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

  Widget _buildCoolingBanner(
    BuildContext context,
    ThemeData theme,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timelapse_rounded,
                      size: 15,
                      color: AppTheme.primaryBlue,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'RESFRIANDO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Text(
                  freezer.remainingFormatted,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryBlue,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          SmoothProgressBar(
            value: freezer.batchProgress,
            minHeight: 5,
            progressColor: AppTheme.primaryBlue,
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerLowest,
            borderRadius: BorderRadius.circular(4),
            duration: AppMotion.durationStandard,
            curve: AppMotion.easeOut,
          ),
        ],
      ),
    );
  }

  Widget _buildReadyBanner(BuildContext context, ThemeData theme) {
    return BreathingGlow(
      isPulsing: true,
      minOpacity: 0.82,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.successGreen.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.successGreen, width: 1.5),
        ),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppTheme.successGreen,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'LOTE PRONTO! PODE RETIRAR',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.successGreen,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoorOpenBanner(ThemeData theme) {
    final openSec = freezer.doorDuration.inSeconds;
    return BreathingGlow(
      isPulsing: true,
      minOpacity: 0.78,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.dangerRed.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.dangerRed, width: 1.5),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.meeting_room_rounded,
                    color: AppTheme.dangerRed,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'PORTA ABERTA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dangerRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Text(
                '${openSec}s',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.dangerRed,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackPrompt(BuildContext context, ThemeData theme) {
    final countdown = freezer.feedbackCountdownSeconds ?? 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.warningAmber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.warningAmber, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ovos prontos?',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: AppTheme.warningAmber,
                ),
              ),
              Text(
                '${countdown}s (OK)',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.warningAmber,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: PressableScale(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      minimumSize: const Size(0, 28),
                    ),
                    onPressed: () {
                      context.read<FreezerCubit>().recordFreezerFeedback(
                        freezer.id,
                        'No ponto',
                      );
                    },
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'No Ponto',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: PressableScale(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      minimumSize: const Size(0, 28),
                    ),
                    onPressed: () {
                      context.read<FreezerCubit>().recordFreezerFeedback(
                        freezer.id,
                        'Mole',
                      );
                    },
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Mole',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: PressableScale(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      minimumSize: const Size(0, 28),
                    ),
                    onPressed: () {
                      context.read<FreezerCubit>().recordFreezerFeedback(
                        freezer.id,
                        'Muito gelado',
                      );
                    },
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Duro',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
    );
  }
}
