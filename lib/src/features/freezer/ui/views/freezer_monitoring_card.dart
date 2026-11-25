import 'dart:math';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_breakpoints.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_motion.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/app_states.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/status_badge.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_feedback_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_live_state.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_status_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/ui/view_models/freezer_monitoring_view_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/ui/views/freezer_config_view.dart';

/// Card de monitoramento do Freezer otimizado para Tablet 11" (Lenovo Idea Tab TB336FU 16:10)
/// e Kiosk Horizontal (SM-A055M/DS) com arquitetura de **Micro-States (atualização direcionada por campo)**:
/// - Cada campo individual (Título, Badge de Porta, Botões de Ação, Cronômetro MM:SS,
///   Temperatura °C, Barra de Progresso, Cabeçalho de Perda Térmica e Gráfico CustomPaint)
///   possui seu próprio [SignalBuilder] isolado em [FreezerItemSignals].
/// - Quando o cronômetro avança a cada 1 segundo, APENAS o texto do tempo e a barra de progresso
///   são atualizados — os botões, cabeçalho, temperatura e gráfico NÃO sofrem rebuild.
class FreezerMonitoringCard extends StatelessWidget {
  final FreezerLiveState? freezer;
  final String? freezerId;
  final FreezerMonitoringViewModel viewModel;

  const FreezerMonitoringCard({
    super.key,
    this.freezer,
    this.freezerId,
    required this.viewModel,
  }) : assert(
         freezer != null || freezerId != null,
         'Informe freezer ou freezerId',
       );

  String get _resolvedFreezerId => freezerId ?? freezer!.freezerId;

  Color _resolveAccentColor({
    required ColorScheme colorScheme,
    required FreezerStatusEnum status,
    required bool isOpen,
    required bool isProbeOk,
  }) {
    if (!isProbeOk || isOpen) return colorScheme.error;
    if (status == FreezerStatusEnum.ready) return AppTheme.successGreen;
    if (status == FreezerStatusEnum.feedbackPending) {
      return AppTheme.warningAmber;
    }
    if (status == FreezerStatusEnum.cooling) return colorScheme.tertiary;
    return colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = AppBreakpoints.isTabletKiosk(context);
    final id = _resolvedFreezerId;
    final item =
        viewModel.itemSignalsOf(id) ??
        (freezer != null ? FreezerItemSignals(freezer!) : null);

    if (item == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, cardConstraints) {
        final hasBoundedHeight = cardConstraints.maxHeight.isFinite;
        final isTallFreezerCard =
            hasBoundedHeight && cardConstraints.maxHeight >= 240;
        final useLargeMetrics = isTablet || isTallFreezerCard;

        // O conteúdo interno do card é construído uma única vez e passado como `child`
        // para que mudanças na borda/cor do Card jamais reconstruam a árvore interna.
        final cardBody = Padding(
          padding: EdgeInsets.symmetric(
            horizontal: useLargeMetrics ? AppSpacing.md : AppSpacing.sm,
            vertical: useLargeMetrics ? 12 : 6,
          ),
          child: Column(
            mainAxisSize:
                hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Topo: Nome + Porta + Ações Rápidas (Cada um com seu próprio Micro-State) ---
              _buildHeaderRow(
                context,
                theme,
                colorScheme,
                item,
                useLargeMetrics: useLargeMetrics,
              ),

              SizedBox(height: useLargeMetrics ? 8 : 4),

              // --- 2. Faixa Principal: Alterna entre Timer/Temp e Prompt de Feedback apenas quando `status == feedbackPending` muda ---
              SignalBuilder(
                builder: (context) {
                  final isFeedback =
                      item.status.value == FreezerStatusEnum.feedbackPending;
                  return AnimatedSwitcher(
                    duration: AppMotion.durationStandard,
                    switchInCurve: AppMotion.easeOut,
                    switchOutCurve: AppMotion.easeOut,
                    child: isFeedback
                        ? KeyedSubtree(
                            key: const ValueKey('panel_feedback'),
                            child: _buildFeedbackPrompt(
                              context,
                              theme,
                              item,
                              useLargeMetrics: useLargeMetrics,
                            ),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('panel_timer_live'),
                            child: _buildPrimaryTimeAndTempSection(
                              context,
                              theme,
                              colorScheme,
                              item,
                              useLargeMetrics: useLargeMetrics,
                            ),
                          ),
                  );
                },
              ),

              SizedBox(height: useLargeMetrics ? 8 : 4),

              // --- 3. Gráfico Térmico junto com o Tempo de Porta Aberta (isolado em micro-states térmicos) ---
              if (hasBoundedHeight)
                Expanded(
                  child: FreezerThermalCurvePanel(
                    itemSignals: item,
                    expandGraph: true,
                    isLarge: useLargeMetrics,
                  ),
                )
              else
                FreezerThermalCurvePanel(
                  itemSignals: item,
                  isLarge: useLargeMetrics,
                ),
            ],
          ),
        );

        // Micro-state da casca do Card: só reconstrói a decoração quando status, isDoorOpen, isSensorOk ou isDefrosting mudam
        return SignalBuilder(
          builder: (context) {
            final status = item.status.value;
            final isOpen = item.isDoorOpen.value;
            final isProbeOk = item.isSensorOk.value;
            final isDefrosting = item.isDefrosting.value;
            final isReady = status == FreezerStatusEnum.ready;
            final isFeedback = status == FreezerStatusEnum.feedbackPending;
            final isCooling = status == FreezerStatusEnum.cooling;

            final Color cardBgColor;
            final Color borderColor;

            if (!isProbeOk || isOpen) {
              cardBgColor = colorScheme.errorContainer.withValues(alpha: 0.30);
              borderColor = colorScheme.error;
            } else if (isDefrosting) {
              // Visual de Motor Off / Standby para indicar que o compressor Frost Free desligou
              cardBgColor = colorScheme.surfaceContainerLowest.withValues(
                alpha: 0.85,
              );
              borderColor = AppTheme.warningAmber.withValues(alpha: 0.75);
            } else if (isReady) {
              cardBgColor = AppTheme.successGreen.withValues(alpha: 0.16);
              borderColor = AppTheme.successGreen;
            } else if (isFeedback) {
              cardBgColor = AppTheme.warningAmber.withValues(alpha: 0.14);
              borderColor = AppTheme.warningAmber;
            } else if (isCooling) {
              cardBgColor = colorScheme.surfaceContainer;
              borderColor = colorScheme.tertiary.withValues(alpha: 0.65);
            } else {
              cardBgColor = colorScheme.surfaceContainerLow;
              borderColor = colorScheme.outlineVariant;
            }

            return GestureDetector(
              key: ValueKey('freezer_card_long_press_${item.freezerId}'),
              behavior: HitTestBehavior.opaque,
              onLongPress: () {
                try {
                  HapticFeedback.mediumImpact();
                } catch (_) {}
                _showFreezerStatusOverrideDialog(context, item);
              },
              child: Card.outlined(
                color: cardBgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusLg,
                  side: BorderSide(
                    color: borderColor,
                    width:
                        (isReady || isOpen || !isProbeOk || isDefrosting)
                            ? 2.0
                            : 1.2,
                  ),
                ),
                child: cardBody,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    FreezerItemSignals item, {
    required bool useLargeMetrics,
  }) {
    return Row(
      children: [
        // Micro-state do ícone de gelo / motor desligado
        SignalBuilder(
          builder: (context) {
            final status = item.status.value;
            final isOpen = item.isDoorOpen.value;
            final isProbeOk = item.isSensorOk.value;
            final isDefrosting = item.isDefrosting.value;
            final isActive =
                status == FreezerStatusEnum.cooling ||
                status == FreezerStatusEnum.ready ||
                isOpen;
            final accentColor = _resolveAccentColor(
              colorScheme: colorScheme,
              status: status,
              isOpen: isOpen,
              isProbeOk: isProbeOk,
            );
            return Icon(
              isDefrosting
                  ? Icons.power_off_rounded
                  : Icons.ac_unit_rounded,
              color: isDefrosting
                  ? AppTheme.warningAmber
                  : (isActive ? accentColor : AppTheme.textMuted),
              size: useLargeMetrics ? 18 : 13,
            );
          },
        ),
        SizedBox(width: useLargeMetrics ? 6 : 4),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Micro-state do Nome do Equipamento Vinculado
                SignalBuilder(
                  builder: (context) {
                    final headerName = item.displayHeaderName.value
                        .toUpperCase();
                    final hasLinked = item.hasLinkedEquipment.value;
                    return Text(
                      headerName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFamily: AppTheme.fontHeading,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        fontSize: useLargeMetrics ? 15 : 11,
                        color: hasLinked
                            ? colorScheme.primary
                            : AppTheme.textSecondary,
                      ),
                    );
                  },
                ),
                SizedBox(width: useLargeMetrics ? 8 : 6),
                // Micro-state do Badge de Porta e Degelo (Frost Free Off)
                SignalBuilder(
                  builder: (context) {
                    final isOpen = item.isDoorOpen.value;
                    final isDefrosting = item.isDefrosting.value;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(
                          label: isOpen ? 'PORTA ABERTA' : 'PORTA FECHADA',
                          icon: isOpen
                              ? Icons.sensor_door_outlined
                              : Icons.door_front_door_rounded,
                          color: isOpen
                              ? colorScheme.error
                              : AppTheme.successGreen,
                          compact: true,
                          subtle: false,
                        ),
                        if (isDefrosting) ...[
                          SizedBox(width: useLargeMetrics ? 6 : 4),
                          StatusBadge(
                            label: 'MOTOR OFF • DEGELO',
                            icon: Icons.power_off_rounded,
                            color: AppTheme.warningAmber,
                            compact: true,
                            subtle: false,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: useLargeMetrics ? 6 : 4),

        // Ações Rápidas: "Pronto" (micro-state de status), "Reiniciar" (100% estático) e "Configurar" (100% estático)
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SignalBuilder(
                builder: (context) {
                  final status = item.status.value;
                  final isIdle = status == FreezerStatusEnum.idle;
                  final isFeedback =
                      status == FreezerStatusEnum.feedbackPending;
                  if (isIdle || isFeedback) {
                    return const SizedBox.shrink();
                  }
                  final isReady = status == FreezerStatusEnum.ready;
                  final isOpen = item.isDoorOpen.value;
                  final hasOvertime = item.hasOvertime.value;
                  final emphasize = isReady || hasOvertime || isOpen;

                  return Padding(
                    padding: EdgeInsets.only(right: useLargeMetrics ? 6 : 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('freezer_mark_ready_${item.freezerId}'),
                        borderRadius: AppSpacing.borderRadiusXs,
                        onTap: () => viewModel.markBatchReadyAndCalibrate(
                          item.freezerId,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: useLargeMetrics ? 12 : 9,
                            vertical: useLargeMetrics ? 7 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withValues(
                              alpha: emphasize ? 0.28 : 0.14,
                            ),
                            borderRadius: AppSpacing.borderRadiusXs,
                            border: Border.all(
                              color: AppTheme.successGreen.withValues(
                                alpha: emphasize ? 0.65 : 0.30,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: useLargeMetrics ? 16 : 13,
                                color: AppTheme.successGreen,
                              ),
                              SizedBox(width: useLargeMetrics ? 5 : 4),
                              Text(
                                'Pronto',
                                style: TextStyle(
                                  fontSize: useLargeMetrics ? 12.5 : 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.successGreen,
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
              // Botão Reiniciar estático — NUNCA sofre rebuild durante ticks do cronômetro ou telemetria!
              Material(
                color: useLargeMetrics
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : Colors.transparent,
                borderRadius: AppSpacing.borderRadiusXs,
                child: InkWell(
                  key: ValueKey('freezer_restart_${item.freezerId}'),
                  borderRadius: AppSpacing.borderRadiusXs,
                  onTap: () => viewModel.restartCycle(item.freezerId),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: useLargeMetrics ? 11 : 8,
                      vertical: useLargeMetrics ? 7 : 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: useLargeMetrics ? 16 : 13,
                          color: AppTheme.textMuted.withValues(alpha: 0.85),
                        ),
                        SizedBox(width: useLargeMetrics ? 5 : 3),
                        Text(
                          'Reiniciar',
                          style: TextStyle(
                            fontSize: useLargeMetrics ? 12.5 : 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: useLargeMetrics ? 4 : 2),
              // Botão Configurar estático — NUNCA sofre rebuild durante ticks do cronômetro ou telemetria!
              Material(
                color: useLargeMetrics
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : Colors.transparent,
                borderRadius: AppSpacing.borderRadiusXs,
                child: InkWell(
                  key: ValueKey('freezer_config_${item.freezerId}'),
                  borderRadius: AppSpacing.borderRadiusXs,
                  onTap: () => _showDoorTimingConfigDialog(context, item),
                  child: Padding(
                    padding: EdgeInsets.all(useLargeMetrics ? 8 : 6),
                    child: Icon(
                      Icons.tune_rounded,
                      size: useLargeMetrics ? 18 : 15,
                      color: AppTheme.textMuted.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryTimeAndTempSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    FreezerItemSignals item, {
    required bool useLargeMetrics,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    // Micro-state 1: Apenas o texto do Cronômetro MM:SS / MM:SS reconstrói a cada 1 segundo
                    SignalBuilder(
                      builder: (context) {
                        final elapsed = item.elapsedFormatted.value;
                        final target = item.targetFormatted.value;
                        final status = item.status.value;
                        final hasOvertime = item.hasOvertime.value;
                        final isDefrosting = item.isDefrosting.value;

                        final Color elapsedColor;
                        if (isDefrosting) {
                          elapsedColor = AppTheme.textMuted;
                        } else if (status == FreezerStatusEnum.ready) {
                          elapsedColor = AppTheme.successGreen;
                        } else if (hasOvertime) {
                          elapsedColor = AppTheme.warningAmber;
                        } else if (status == FreezerStatusEnum.idle) {
                          elapsedColor = AppTheme.textSecondary;
                        } else {
                          elapsedColor = colorScheme.onSurface;
                        }

                        return Text.rich(
                          TextSpan(
                            text: elapsed,
                            style: TextStyle(
                              fontFamily: AppTheme.fontHeading,
                              fontSize: useLargeMetrics ? 42 : 30,
                              height: 1.0,
                              fontWeight: FontWeight.w900,
                              color: elapsedColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                            children: [
                              TextSpan(
                                text: ' / $target',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontBody,
                                  fontSize: useLargeMetrics ? 21 : 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          key: ValueKey('freezer_time_${item.freezerId}'),
                        );
                      },
                    ),
                    SizedBox(width: useLargeMetrics ? 12 : 8),
                    // Micro-state 2: Rótulo de status operacional (só reconstrói quando status, porta ou degelo mudam)
                    SignalBuilder(
                      builder: (context) {
                        final isOpen = item.isDoorOpen.value;
                        final isDefrosting = item.isDefrosting.value;
                        final status = item.status.value;
                        final isReady = status == FreezerStatusEnum.ready;
                        final isCooling = status == FreezerStatusEnum.cooling;
                        final isIdle = status == FreezerStatusEnum.idle;

                        final String statusLabel;
                        final Color statusColor;

                        if (isOpen) {
                          statusLabel = 'PERDENDO TEMPERATURA';
                          statusColor = colorScheme.error;
                        } else if (isDefrosting) {
                          statusLabel = isIdle
                              ? 'MOTOR EM DEGELO • NÃO COLOCAR FORMAS'
                              : 'MOTOR EM DEGELO • TEMPO PAUSADO (NÃO ABRIR)';
                          statusColor = AppTheme.warningAmber;
                        } else if (isReady) {
                          statusLabel = 'LOTE PRONTO! PODE RETIRAR';
                          statusColor = AppTheme.successGreen;
                        } else if (isCooling) {
                          statusLabel = 'CRISTALIZANDO';
                          statusColor = colorScheme.tertiary;
                        } else {
                          statusLabel = 'AGUARDANDO FORMINHAS';
                          statusColor = AppTheme.textMuted;
                        }

                        return Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: useLargeMetrics
                                ? (isIdle && !isDefrosting ? 12 : 13)
                                : (isIdle && !isDefrosting ? 9.5 : 10),
                            fontWeight: (isIdle && !isDefrosting)
                                ? FontWeight.w600
                                : FontWeight.w900,
                            letterSpacing: 0.3,
                            color: statusColor,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: useLargeMetrics ? 12 : 8),
            // Micro-state 3: Temperatura atual (°C) — só reconstrói quando a temperatura muda em 0.1 °C
            SignalBuilder(
              builder: (context) {
                final fmtTemp = item.formattedTemp.value;
                final isProbeOk = item.isSensorOk.value;
                final isOpen = item.isDoorOpen.value;
                final isDefrosting = item.isDefrosting.value;
                final isReady = item.status.value == FreezerStatusEnum.ready;

                return AnimatedValueText(
                  value: fmtTemp,
                  pulseScale: 1.03,
                  style: TextStyle(
                    fontFamily: AppTheme.fontHeading,
                    fontSize: useLargeMetrics ? 28 : 20,
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                    color: !isProbeOk || isOpen
                        ? colorScheme.error
                        : isDefrosting
                        ? AppTheme.warningAmber
                        : isReady
                        ? AppTheme.successGreen
                        : colorScheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: useLargeMetrics ? 8 : 5),
        // Micro-state 4: Barra de progresso do ciclo
        SignalBuilder(
          builder: (context) {
            final progress = item.progress.value;
            final isReady = item.status.value == FreezerStatusEnum.ready;
            final isOpen = item.isDoorOpen.value;
            final isDefrosting = item.isDefrosting.value;

            return SmoothProgressBar(
              value: progress,
              minHeight: useLargeMetrics ? 8 : 5,
              progressColor: isDefrosting
                  ? AppTheme.warningAmber
                  : isReady
                  ? AppTheme.successGreen
                  : (isOpen ? colorScheme.error : colorScheme.tertiary),
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(useLargeMetrics ? 6 : 4),
              duration: AppMotion.durationStandard,
              curve: AppMotion.easeOut,
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeedbackPrompt(
    BuildContext context,
    ThemeData theme,
    FreezerItemSignals item, {
    required bool useLargeMetrics,
  }) {
    final btnMinHeight = useLargeMetrics ? 42.0 : 32.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: useLargeMetrics ? 12 : 8,
        vertical: useLargeMetrics ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: AppTheme.warningAmber.withValues(alpha: 0.16),
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ponto do Chocolate?',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: useLargeMetrics ? 13 : 10.5,
                  color: AppTheme.warningAmber,
                ),
              ),
              // Micro-state do countdown de 30s: atualiza apenas este Text, mantendo os 3 botões abaixo 100% estáticos!
              SignalBuilder(
                builder: (context) {
                  final countdown = item.feedbackCountdownSeconds.value;
                  return Text(
                    '${countdown}s → OK Automático',
                    style: TextStyle(
                      fontSize: useLargeMetrics ? 12 : 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.warningAmber,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: useLargeMetrics ? 8 : 4),
          Row(
            children: [
              Expanded(
                child: PressableScale(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: useLargeMetrics ? 8 : 4,
                      ),
                      minimumSize: Size(0, btnMinHeight),
                      backgroundColor: AppTheme.successGreen.withValues(
                        alpha: 0.28,
                      ),
                    ),
                    onPressed: () {
                      viewModel.recordFeedback(
                        item.freezerId,
                        FreezerFeedbackEnum.onPoint,
                      );
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'No Ponto',
                        style: TextStyle(
                          fontSize: useLargeMetrics ? 12.5 : 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.successGreen,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: useLargeMetrics ? 8 : 4),
              Expanded(
                child: PressableScale(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: useLargeMetrics ? 8 : 4,
                      ),
                      minimumSize: Size(0, btnMinHeight),
                      backgroundColor: AppTheme.warningAmber.withValues(
                        alpha: 0.28,
                      ),
                    ),
                    onPressed: () {
                      viewModel.recordFeedback(
                        item.freezerId,
                        FreezerFeedbackEnum.soft,
                      );
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Ainda Mole (+3m)',
                        style: TextStyle(
                          fontSize: useLargeMetrics ? 12 : 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.warningAmber,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: useLargeMetrics ? 8 : 4),
              Expanded(
                child: PressableScale(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: useLargeMetrics ? 8 : 4,
                      ),
                      minimumSize: Size(0, btnMinHeight),
                      backgroundColor: AppTheme.primaryBlue.withValues(
                        alpha: 0.25,
                      ),
                    ),
                    onPressed: () {
                      viewModel.recordFeedback(
                        item.freezerId,
                        FreezerFeedbackEnum.overchilled,
                      );
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Muito Gelado',
                        style: TextStyle(
                          fontSize: useLargeMetrics ? 12 : 9.5,
                          fontWeight: FontWeight.w800,
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

  void _showDoorTimingConfigDialog(
    BuildContext context,
    FreezerItemSignals item,
  ) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FreezerConfigView(
          viewModel: viewModel,
          item: item,
        ),
      ),
    );
  }

  void _showFreezerStatusOverrideDialog(
    BuildContext context,
    FreezerItemSignals item,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = item.rawState.value;
    final lastClose =
        state.lastDoorCloseAt ??
        state.doorTransitions.where((t) => !t.isOpen).lastOrNull?.timestamp;

    String doorCloseElapsedText;
    if (lastClose != null) {
      final secs = max(0, DateTime.now().difference(lastClose).inSeconds);
      final mm = (secs ~/ 60).toString().padLeft(2, '0');
      final ss = (secs % 60).toString().padLeft(2, '0');
      doorCloseElapsedText =
          'Porta fechou há $mm:$ss • Inicia já descontando esse tempo';
    } else {
      doorCloseElapsedText =
          'Sem fechamento de porta recente • Inicia contagem do 00:00';
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: ValueKey('freezer_status_override_dialog_${item.freezerId}'),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          titlePadding: const EdgeInsets.fromLTRB(16, 10, 10, 4),
          contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          title: Row(
            children: [
              Icon(
                Icons.ac_unit_rounded,
                color: colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'STATUS DO FREEZER • ${item.displayHeaderName.value.toUpperCase()}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Fechar',
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _StatusOverrideOptionTile(
                            tileKey: ValueKey(
                              'status_override_from_door_close_${item.freezerId}',
                            ),
                            icon: Icons.history_toggle_off_rounded,
                            color: colorScheme.tertiary,
                            title:
                                'Coloquei Ovos (Contar desde que fechou a porta)',
                            subtitle: doorCloseElapsedText,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              viewModel.startCycleFromLastDoorClose(
                                item.freezerId,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatusOverrideOptionTile(
                            tileKey: ValueKey(
                              'status_override_start_zero_${item.freezerId}',
                            ),
                            icon: Icons.play_circle_fill_rounded,
                            color: colorScheme.primary,
                            title: 'Iniciar Novo Ciclo do 00:00',
                            subtitle:
                                'Zera o cronômetro e começa a cristalização agora',
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              viewModel.restartCycle(item.freezerId);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _StatusOverrideOptionTile(
                            tileKey: ValueKey(
                              'status_override_empty_idle_${item.freezerId}',
                            ),
                            icon: Icons.pause_circle_filled_rounded,
                            color: AppTheme.textSecondary,
                            title: 'Freezer Vazio / Sem Ovos',
                            subtitle:
                                'Para a contagem sem alterar a calibração',
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              viewModel.cancelCycle(item.freezerId);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatusOverrideOptionTile(
                            tileKey: ValueKey(
                              'status_override_mark_ready_${item.freezerId}',
                            ),
                            icon: Icons.check_circle_rounded,
                            color: AppTheme.successGreen,
                            title: 'Lote Pronto (Finalizar e Calibrar)',
                            subtitle:
                                'Finaliza o lote e calibra os próximos ciclos',
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              viewModel.markBatchReadyAndCalibrate(
                                item.freezerId,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatusOverrideOptionTile(
                    tileKey: ValueKey(
                      'status_override_defrost_toggle_${item.freezerId}',
                    ),
                    icon: state.isDefrosting
                        ? Icons.power_rounded
                        : Icons.power_off_rounded,
                    color: state.isDefrosting
                        ? AppTheme.successGreen
                        : AppTheme.warningAmber,
                    title: state.isDefrosting
                        ? 'Motor Religou (Encerrar Modo Degelo)'
                        : 'Marcar Motor em Degelo (Frost Free Desligado)',
                    subtitle: state.isDefrosting
                        ? 'Retoma a contagem do ciclo e soma compensação térmica'
                        : 'Pausa o cronômetro e avisa a equipe para não abrir nem colocar formas',
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      viewModel.setManualDefrostMode(
                        item.freezerId,
                        isDefrosting: !state.isDefrosting,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _StatusOverrideOptionTile extends StatelessWidget {
  final Key tileKey;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _StatusOverrideOptionTile({
    required this.tileKey,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        side: BorderSide(color: color.withValues(alpha: 0.45)),
      ),
      child: InkWell(
        key: tileKey,
        borderRadius: AppSpacing.borderRadiusMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        height: 1.15,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        height: 1.15,
                        color: AppTheme.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.8),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painel da Curva de Área com Tempo de Porta Aberta ao vivo e Perda de Temperatura.
/// Isolado em 2 micro-states independentes:
/// 1) Cabeçalho de tempo de porta aberta / ΔT / penalidade
/// 2) Gráfico [CustomPaint] (só repinta quando chega amostra térmica ou transição de porta, nunca no tick de 1s do relógio!)
final class FreezerThermalCurvePanel extends StatelessWidget {
  final FreezerLiveState? freezer;
  final FreezerItemSignals? itemSignals;
  final bool expandGraph;
  final bool isLarge;

  const FreezerThermalCurvePanel({
    super.key,
    this.freezer,
    this.itemSignals,
    this.expandGraph = false,
    this.isLarge = false,
  }) : assert(
         freezer != null || itemSignals != null,
         'Informe freezer ou itemSignals',
       );

  static Color resolveThermalBandColor(
    double temperature,
    ColorScheme colorScheme,
  ) {
    if (temperature <= 0.0) {
      return colorScheme.tertiary;
    }
    if (temperature <= 8.0) {
      return AppTheme.warningAmber;
    }
    return colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final item = itemSignals ?? FreezerItemSignals(freezer!);
    final effectiveLarge = isLarge || AppBreakpoints.isTabletKiosk(context);

    final graphWidget = RepaintBoundary(
      child: SignalBuilder(
        builder: (context) {
          final history = item.temperatureHistory.value;
          final doorTransitions = item.doorTransitions.value;
          final baseTemp = item.effectiveBaselineTemp.value;
          final currentTemp = item.currentTemp.value;
          final currentBandColor = resolveThermalBandColor(
            currentTemp,
            colorScheme,
          );

          return CustomPaint(
            painter: _ThermalCurvePainter(
              history: history,
              doorTransitions: doorTransitions,
              baselineTemp: baseTemp,
              currentTemp: currentTemp,
              lineColor: currentBandColor,
              coldColor: colorScheme.tertiary,
              warmColor: AppTheme.warningAmber,
              hotColor: colorScheme.error,
              baselineColor: colorScheme.outline,
              doorOpenColor: colorScheme.error,
              doorCloseColor: AppTheme.successGreen,
            ),
          );
        },
      ),
    );

    return Column(
      mainAxisSize: expandGraph ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Micro-state do cabeçalho de porta aberta, degelo e recuperação térmica em tempo real
        SignalBuilder(
          builder: (context) {
            final isOpen = item.isDoorOpen.value;
            final isDefrosting = item.isDefrosting.value;
            final defrostDelta = item.defrostDeltaTemp.value;
            final accDefrostSec = item.accumulatedDefrostSeconds.value;
            final delta = item.doorDeltaTemp.value;
            final recovered = item.recoveredDegrees.value;
            final doorOpenCount = item.doorOpenCount.value;
            final penaltySec = item.accumulatedPenaltySeconds.value;
            final currentTemp = item.currentTemp.value;
            final hasDoorShift =
                delta.abs() >= 0.1 || recovered >= 0.1 || doorOpenCount > 0;
            final showHeaderRow =
                isOpen ||
                isDefrosting ||
                hasDoorShift ||
                penaltySec > 0 ||
                accDefrostSec > 0;

            if (!showHeaderRow) {
              return const SizedBox.shrink();
            }

            final Color indicatorColor = isOpen
                ? colorScheme.error
                : isDefrosting
                ? AppTheme.warningAmber
                : resolveThermalBandColor(currentTemp, colorScheme);

            final sign = delta >= 0 ? '+' : '';
            final totalRise = max(0.0, delta);
            final String doorShiftLabel;
            if (isOpen) {
              doorShiftLabel = 'Perda: $sign${delta.toStringAsFixed(1)} °C ▲';
            } else if (isDefrosting) {
              doorShiftLabel =
                  'Subiu no degelo: +${defrostDelta.toStringAsFixed(1)} °C ▲';
            } else if (totalRise >= 0.1) {
              doorShiftLabel =
                  'Recuperado: -${recovered.toStringAsFixed(1)} / ${totalRise.toStringAsFixed(1)} °C ▼';
            } else {
              doorShiftLabel =
                  'Recuperado: -${recovered.toStringAsFixed(1)} °C ▼';
            }

            return Padding(
              padding: EdgeInsets.only(bottom: effectiveLarge ? 4 : 2),
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
                          if (isOpen) ...[
                            Icon(
                              Icons.timer_outlined,
                              size: effectiveLarge ? 14 : 11,
                              color: colorScheme.error,
                            ),
                            SizedBox(width: effectiveLarge ? 4 : 3),
                            // Micro-state aninhado exclusivamente para os segundos da porta aberta
                            SignalBuilder(
                              builder: (context) {
                                return Text(
                                  'ABERTA HÁ ${item.currentDoorOpenFormatted.value}',
                                  style: TextStyle(
                                    fontSize: effectiveLarge ? 12 : 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: colorScheme.error,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: effectiveLarge ? 8 : 6),
                          ] else if (isDefrosting) ...[
                            Icon(
                              Icons.power_off_rounded,
                              size: effectiveLarge ? 14 : 11,
                              color: AppTheme.warningAmber,
                            ),
                            SizedBox(width: effectiveLarge ? 4 : 3),
                            SignalBuilder(
                              builder: (context) {
                                return Text(
                                  'EM DEGELO HÁ ${item.currentDefrostFormatted.value}',
                                  style: TextStyle(
                                    fontSize: effectiveLarge ? 12 : 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.warningAmber,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: effectiveLarge ? 8 : 6),
                          ],
                          if (isOpen || isDefrosting || hasDoorShift) ...[
                            Icon(
                              (isOpen || isDefrosting)
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              size: effectiveLarge ? 15 : 12,
                              color: indicatorColor,
                            ),
                            SizedBox(width: effectiveLarge ? 4 : 3),
                            Text(
                              doorShiftLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: effectiveLarge ? 12.5 : 10,
                                fontWeight: FontWeight.w800,
                                color: indicatorColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (penaltySec > 0 || accDefrostSec > 0)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '+${penaltySec + accDefrostSec}s no alvo',
                        style: TextStyle(
                          fontSize: effectiveLarge ? 11.5 : 9,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warningAmber.withValues(alpha: 0.8),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        if (expandGraph)
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: effectiveLarge ? 36 : 18),
              child: graphWidget,
            ),
          )
        else
          SizedBox(
            height: effectiveLarge ? 48 : 24,
            child: graphWidget,
          ),
      ],
    );
  }
}

final class _ThermalCurvePainter extends CustomPainter {
  final List<({DateTime timestamp, double temperature})> history;
  final List<({DateTime timestamp, bool isOpen, double temperature})>
  doorTransitions;
  final double baselineTemp;
  final double currentTemp;
  final Color lineColor;
  final Color coldColor;
  final Color warmColor;
  final Color hotColor;
  final Color baselineColor;
  final Color doorOpenColor;
  final Color doorCloseColor;

  const _ThermalCurvePainter({
    required this.history,
    required this.doorTransitions,
    required this.baselineTemp,
    required this.currentTemp,
    required this.lineColor,
    required this.coldColor,
    required this.warmColor,
    required this.hotColor,
    required this.baselineColor,
    required this.doorOpenColor,
    required this.doorCloseColor,
  });

  /// Constrói o gradiente vertical por faixa térmica:
  /// - > 8,0 °C (topo): [hotColor] (Vermelho)
  /// - 0,1 °C .. 8,0 °C (meio): [warmColor] (Âmbar)
  /// - <= 0,0 °C (base): [coldColor] (Azul)
  Shader _buildThermalShader(
    Size size,
    double Function(double) yForTemp, {
    required bool isFill,
  }) {
    final rect = Offset.zero & size;
    final stop8 = (yForTemp(8.0) / size.height).clamp(0.0, 1.0);
    final stop0 = (yForTemp(0.0) / size.height).clamp(0.0, 1.0);

    Color applyAlpha(Color c, double yStop) {
      if (!isFill) return c;
      // Mais opaco no topo e suave próximo à base do gráfico
      final alpha = (0.30 - (yStop * 0.22)).clamp(0.06, 0.30);
      return c.withValues(alpha: alpha);
    }

    const eps = 0.015;
    final s8a = (stop8 - eps).clamp(0.0, 1.0);
    final s8b = (stop8 + eps).clamp(s8a, 1.0);
    final s0a = max(s8b, (stop0 - eps).clamp(0.0, 1.0));
    final s0b = (stop0 + eps).clamp(s0a, 1.0);

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [0.0, s8a, s8b, s0a, s0b, 1.0],
      colors: [
        applyAlpha(hotColor, 0.0),
        applyAlpha(hotColor, s8a),
        applyAlpha(warmColor, s8b),
        applyAlpha(warmColor, s0a),
        applyAlpha(coldColor, s0b),
        applyAlpha(coldColor, 1.0),
      ],
    ).createShader(rect);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final samples = history.isNotEmpty
        ? history
        : [
            (timestamp: DateTime.now(), temperature: baselineTemp),
            (timestamp: DateTime.now(), temperature: currentTemp),
          ];

    double minT = min(baselineTemp, currentTemp);
    double maxT = max(baselineTemp, currentTemp);
    for (final pt in samples) {
      if (pt.temperature < minT) minT = pt.temperature;
      if (pt.temperature > maxT) maxT = pt.temperature;
    }

    if ((maxT - minT) < 2.0) {
      final mid = (maxT + minT) / 2.0;
      minT = mid - 1.0;
      maxT = mid + 1.0;
    } else {
      final pad = (maxT - minT) * 0.15;
      minT -= pad;
      maxT += pad;
    }

    double yForTemp(double t) {
      final norm = ((t - minT) / (maxT - minT)).clamp(0.0, 1.0);
      return size.height - (norm * (size.height - 4)) - 2;
    }

    final baseY = yForTemp(baselineTemp);
    final dashPaint = Paint()
      ..color = baselineColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, baseY),
        Offset(min(startX + dashWidth, size.width), baseY),
        dashPaint,
      );
      startX += dashWidth + dashSpace;
    }

    final count = samples.length;
    final points = <Offset>[];
    if (count == 1) {
      final y = yForTemp(samples.first.temperature);
      points.add(Offset(0, y));
      points.add(Offset(size.width, y));
    } else {
      for (int i = 0; i < count; i++) {
        final x = (i / (count - 1)) * (size.width - 4) + 2;
        final y = yForTemp(samples[i].temperature);
        points.add(Offset(x, y));
      }
    }

    final curvePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      curvePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(curvePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = _buildThermalShader(size, yForTemp, isFill: true)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..shader = _buildThermalShader(size, yForTemp, isFill: false)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(curvePath, strokePaint);

    if (doorTransitions.isNotEmpty && samples.length >= 2) {
      final firstTs = samples.first.timestamp.millisecondsSinceEpoch;
      final lastTs = samples.last.timestamp.millisecondsSinceEpoch;
      final spanMs = max(1, lastTs - firstTs);

      for (final tr in doorTransitions) {
        final trMs = tr.timestamp.millisecondsSinceEpoch;
        if (trMs >= firstTs && trMs <= lastTs) {
          final frac = ((trMs - firstTs) / spanMs).clamp(0.0, 1.0);
          final x = frac * (size.width - 4) + 2;
          final y = yForTemp(tr.temperature);
          final markerColor = tr.isOpen ? doorOpenColor : doorCloseColor;

          final markerLinePaint = Paint()
            ..color = markerColor.withValues(alpha: 0.6)
            ..strokeWidth = 1.0;
          canvas.drawLine(
            Offset(x, 0),
            Offset(x, size.height),
            markerLinePaint,
          );

          final dotPaint = Paint()..color = markerColor;
          canvas.drawCircle(Offset(x, y), 2.8, dotPaint);
        }
      }
    }

    final lastPt = points.last;
    canvas.drawCircle(
      lastPt,
      5.0,
      Paint()..color = lineColor.withValues(alpha: 0.25),
    );
    canvas.drawCircle(lastPt, 2.8, Paint()..color = lineColor);
  }

  @override
  bool shouldRepaint(covariant _ThermalCurvePainter oldDelegate) {
    return oldDelegate.currentTemp != currentTemp ||
        oldDelegate.baselineTemp != baselineTemp ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.coldColor != coldColor ||
        oldDelegate.warmColor != warmColor ||
        oldDelegate.hotColor != hotColor ||
        oldDelegate.history.length != history.length ||
        oldDelegate.doorTransitions.length != doorTransitions.length;
  }
}

/// Zona que agrupa e renderiza os freezers ativos sem reconstruir os cards a cada 1s.
/// Cada [FreezerMonitoringCard] recebe apenas seu `freezerId` estático e gerencia seus
/// próprios micro-states internamente via [FreezerItemSignals].
class FreezerMonitoringZone extends StatelessWidget {
  final FreezerMonitoringViewModel viewModel;

  const FreezerMonitoringZone({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final hasF1 = viewModel.itemSignalsOf('f1') != null;
    final hasF2 = viewModel.itemSignalsOf('f2') != null;

    if (!hasF1 && !hasF2) {
      return const AppEmptyState(
        icon: Icons.ac_unit_rounded,
        title: 'Nenhum freezer conectado',
        subtitle: 'Aguardando telemetria das câmaras frias no ESP32',
      );
    }

    final isTablet = AppBreakpoints.isTabletKiosk(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.maxHeight.isFinite;

        final card1 = FreezerMonitoringCard(
          key: const ValueKey('card_f1'),
          freezerId: 'f1',
          viewModel: viewModel,
        );
        final card2 = FreezerMonitoringCard(
          key: const ValueKey('card_f2'),
          freezerId: 'f2',
          viewModel: viewModel,
        );

        return Column(
          mainAxisSize:
              hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasF1)
              if (hasBoundedHeight) Expanded(child: card1) else card1,
            if (hasF1 && hasF2)
              SizedBox(height: isTablet ? AppSpacing.sm : 6),
            if (hasF2)
              if (hasBoundedHeight) Expanded(child: card2) else card2,
          ],
        );
      },
    );
  }
}
