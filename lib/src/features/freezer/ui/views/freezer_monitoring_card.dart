import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_motion.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_feedback_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_live_state.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_status_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/ui/view_models/freezer_monitoring_view_model.dart';

/// Card de monitoramento e controle adaptativo de freezer.
/// Aplica diretrizes estritas de Material Design 3 e alta densidade.
class FreezerMonitoringCard extends StatelessWidget {
  final FreezerLiveState freezer;
  final FreezerMonitoringViewModel viewModel;

  const FreezerMonitoringCard({
    super.key,
    required this.freezer,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isOpen = freezer.isDoorOpen;
    final isProbeOk = freezer.isSensorOk;
    final isReady = freezer.status == FreezerStatusEnum.ready;
    final isFeedback = freezer.status == FreezerStatusEnum.feedbackPending;
    final isCooling = freezer.status == FreezerStatusEnum.cooling;

    Color cardBgColor;
    Color borderColor;
    Color accentColor;

    if (!isProbeOk || isOpen) {
      cardBgColor = AppTheme.dangerRed.withValues(alpha: 0.16);
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
    } else if (isCooling) {
      cardBgColor = colorScheme.surfaceContainer;
      borderColor = colorScheme.outlineVariant;
      accentColor = colorScheme.primary;
    } else {
      // Idle
      cardBgColor = colorScheme.surfaceContainerLow;
      borderColor = colorScheme.outlineVariant.withValues(alpha: 0.6);
      accentColor = colorScheme.onSurfaceVariant;
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
            // --- Row 1: Header (Nome, Tag Adaptativo, Temperatura Grande) ---
            Row(
              children: [
                Icon(Icons.ac_unit_rounded, color: accentColor, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
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
                            const SizedBox(width: 6),
                            _buildCalibrationBadge(context),
                          ],
                        ),
                      ),
                      Text(
                        freezer.freezerId == 'f1'
                            ? 'Câmara de Cristalização'
                            : 'Congelamento Rápido',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Temperatura com fonte tabular
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

            // --- Row 2: Banner de Estado Animado ---
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
                          : isCooling
                              ? KeyedSubtree(
                                  key: const ValueKey('banner_cooling'),
                                  child: _buildCoolingBanner(
                                      context, theme, accentColor),
                                )
                              : KeyedSubtree(
                                  key: const ValueKey('banner_idle'),
                                  child: _buildIdleBanner(context, theme),
                                ),
            ),

            const SizedBox(height: 6),

            // --- Row 3: Mini footer com ferramentas rápidas ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (freezer.accumulatedPenaltySeconds > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 11,
                        color: AppTheme.warningAmber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${freezer.accumulatedPenaltySeconds}s penalidade',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warningAmber,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Base: ${(freezer.calibratedBaseSeconds / 60).round()} min',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),

                // Botão de Ação Manual
                PressableScale(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () {
                      if (isCooling) {
                        viewModel.cancelCycle(freezer.freezerId);
                      } else {
                        viewModel.startManualCycle(freezer.freezerId);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        isCooling ? 'Cancelar Ciclo' : 'Iniciar Ciclo',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCooling
                              ? colorScheme.error
                              : colorScheme.primary,
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

  Widget _buildCalibrationBadge(BuildContext context) {
    final isCalibrated = freezer.isCalibrated;
    final color = isCalibrated ? AppTheme.successGreen : AppTheme.primaryBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        isCalibrated ? 'CALIBRADO' : 'APRENDENDO',
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
          color: color,
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
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
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
                      'CRISTALIZANDO',
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
            value: freezer.progress,
            minHeight: 5,
            progressColor: AppTheme.primaryBlue,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(4),
            duration: AppMotion.durationStandard,
            curve: AppMotion.easeOut,
          ),
        ],
      ),
    );
  }

  Widget _buildIdleBanner(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.hourglass_empty_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Aguardando Forminhas',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          PressableScale(
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: const Size(0, 26),
              ),
              onPressed: () => viewModel.startManualCycle(freezer.freezerId),
              child: const Text('Carregar', style: TextStyle(fontSize: 10)),
            ),
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
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                'Ponto do Chocolate?',
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
                      backgroundColor:
                          AppTheme.successGreen.withValues(alpha: 0.3),
                    ),
                    onPressed: () {
                      viewModel.recordFeedback(
                        freezer.freezerId,
                        FreezerFeedbackEnum.onPoint,
                      );
                    },
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'No Ponto',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successGreen,
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
                      backgroundColor:
                          AppTheme.warningAmber.withValues(alpha: 0.3),
                    ),
                    onPressed: () {
                      viewModel.recordFeedback(
                        freezer.freezerId,
                        FreezerFeedbackEnum.soft,
                      );
                    },
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Ainda Mole (+3m)',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warningAmber,
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
                      backgroundColor:
                          AppTheme.primaryBlue.withValues(alpha: 0.25),
                    ),
                    onPressed: () {
                      viewModel.recordFeedback(
                        freezer.freezerId,
                        FreezerFeedbackEnum.overchilled,
                      );
                    },
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Muito Gelado',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
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

/// Zona que agrupa e renderiza todos os freezers ativos com Signals
class FreezerMonitoringZone extends StatelessWidget {
  final FreezerMonitoringViewModel viewModel;

  const FreezerMonitoringZone({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final list = viewModel.activeFreezers.value;
        if (list.isEmpty) {
          return const Center(child: Text('Nenhum freezer conectado'));
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < list.length; i++) ...[
              FreezerMonitoringCard(
                freezer: list[i],
                viewModel: viewModel,
              ),
              if (i < list.length - 1) const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}
