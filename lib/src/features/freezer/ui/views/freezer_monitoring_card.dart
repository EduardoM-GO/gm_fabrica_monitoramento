import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_motion.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/app_states.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/status_badge.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_feedback_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_live_state.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_status_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/ui/view_models/freezer_monitoring_view_model.dart';

/// Card enxuto de monitoramento do Freezer para o operador:
/// Exibe apenas os 5 sinais essenciais:
/// 1. Temperatura atual
/// 2. Status da porta (Aberta / Fechada)
/// 3. Quanto alterou a temperatura desde o último evento da porta + Curva de Área limpa
/// 4. Quanto tempo passou / Qual é o tempo alvo (MM:SS / MM:SS)
/// 5. Botão discreto ("Reiniciar") caso a regra automática do sensor de porta precise de ajuste manual
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

    final Color cardBgColor;
    final Color borderColor;
    final Color accentColor;

    if (!isProbeOk || isOpen) {
      cardBgColor = colorScheme.errorContainer.withValues(alpha: 0.30);
      borderColor = colorScheme.error;
      accentColor = colorScheme.error;
    } else if (isReady) {
      cardBgColor = AppTheme.successGreen.withValues(alpha: 0.16);
      borderColor = AppTheme.successGreen;
      accentColor = AppTheme.successGreen;
    } else if (isFeedback) {
      cardBgColor = AppTheme.warningAmber.withValues(alpha: 0.14);
      borderColor = AppTheme.warningAmber;
      accentColor = AppTheme.warningAmber;
    } else if (isCooling) {
      cardBgColor = colorScheme.surfaceContainer;
      borderColor = colorScheme.tertiary.withValues(alpha: 0.65);
      accentColor = colorScheme.tertiary;
    } else {
      cardBgColor = colorScheme.surfaceContainerLow;
      borderColor = colorScheme.outlineVariant;
      accentColor = colorScheme.onSurfaceVariant;
    }

    return Card.outlined(
      color: cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        side: BorderSide(
          color: borderColor,
          width: (isReady || isOpen || !isProbeOk) ? 2.0 : 1.2,
        ),
      ),
      child: AnimatedContainer(
        duration: AppMotion.durationStandard,
        curve: AppMotion.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. Topo: Nome + Status da Porta Unificado + Config Discreta + Temperatura Atual ---
            Row(
              children: [
                Icon(
                  Icons.ac_unit_rounded,
                  color: accentColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          freezer.name.toUpperCase(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontFamily: AppTheme.fontHeading,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            fontSize: 12,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: isOpen ? 'PORTA ABERTA' : 'PORTA FECHADA',
                          icon: isOpen
                              ? Icons.sensor_door_outlined
                              : Icons.door_front_door_rounded,
                          color: isOpen
                              ? colorScheme.error
                              : AppTheme.successGreen,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Botão tímido de configuração dos tempos de porta do sensor
                SizedBox(
                  width: 26,
                  height: 26,
                  child: IconButton(
                    key: ValueKey('freezer_config_${freezer.freezerId}'),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Configurar tempos do sensor de porta',
                    onPressed: () => _showDoorTimingConfigDialog(context),
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 15,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Temperatura Atual em destaque tabular
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: AppSpacing.borderRadiusXs,
                  ),
                  child: Text(
                    isProbeOk
                        ? '${freezer.currentTemp.toStringAsFixed(1)} °C'
                        : '--.- °C',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isProbeOk
                          ? colorScheme.onSurface
                          : colorScheme.error,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // --- 2. Curva de Área Limpa + Alteração desde Último Evento da Porta ---
            FreezerThermalCurvePanel(freezer: freezer),

            const SizedBox(height: 6),

            // --- 3. Painel de Tempo Passado / Tempo Alvo (ou Feedback Rápido pós-retirada) ---
            AnimatedSwitcher(
              duration: AppMotion.durationStandard,
              switchInCurve: AppMotion.easeOut,
              switchOutCurve: AppMotion.easeOut,
              child: isFeedback
                  ? KeyedSubtree(
                      key: const ValueKey('panel_feedback'),
                      child: _buildFeedbackPrompt(context, theme),
                    )
                  : KeyedSubtree(
                      key: ValueKey('panel_timer_${freezer.status.name}'),
                      child: _buildTimerAndControlSection(
                        context,
                        theme,
                        accentColor,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Seção unificada: mostra "Tempo Passado / Tempo Alvo" (ex: 08:30 / 20:00),
  /// barra de progresso e o botão tímido de Reiniciar Contagem no canto.
  Widget _buildTimerAndControlSection(
    BuildContext context,
    ThemeData theme,
    Color accentColor,
  ) {
    final colorScheme = theme.colorScheme;
    final isOpen = freezer.isDoorOpen;
    final isReady = freezer.status == FreezerStatusEnum.ready;
    final isCooling = freezer.status == FreezerStatusEnum.cooling;

    final String statusLabel;
    final Color statusColor;

    if (isOpen) {
      statusLabel = 'PORTA ABERTA';
      statusColor = colorScheme.error;
    } else if (isReady) {
      statusLabel = 'LOTE PRONTO! PODE RETIRAR';
      statusColor = AppTheme.successGreen;
    } else if (isCooling) {
      statusLabel = 'CRISTALIZANDO';
      statusColor = colorScheme.tertiary;
    } else {
      statusLabel = 'AGUARDANDO FORMINHAS';
      statusColor = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isReady
            ? AppTheme.successGreen.withValues(alpha: 0.18)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tempo Passado / Tempo Alvo + Estado
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${freezer.elapsedFormatted} / ${freezer.targetFormatted}',
                        key: ValueKey('freezer_time_${freezer.freezerId}'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Botão tímido (discreto) para reiniciar/iniciar caso a regra do sensor falhe
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      key: ValueKey('freezer_restart_${freezer.freezerId}'),
                      borderRadius: AppSpacing.borderRadiusXs,
                      onTap: () => viewModel.restartCycle(freezer.freezerId),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 13,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.75,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Reiniciar',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.75,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isCooling || isReady) ...[
                      const SizedBox(width: 2),
                      InkWell(
                        key: ValueKey('freezer_cancel_${freezer.freezerId}'),
                        borderRadius: AppSpacing.borderRadiusXs,
                        onTap: () => viewModel.cancelCycle(freezer.freezerId),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 3,
                          ),
                          child: Icon(
                            Icons.stop_circle_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          SmoothProgressBar(
            value: freezer.progress,
            minHeight: 5,
            progressColor: isReady
                ? AppTheme.successGreen
                : (isOpen ? colorScheme.error : colorScheme.tertiary),
            backgroundColor: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(4),
            duration: AppMotion.durationStandard,
            curve: AppMotion.easeOut,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackPrompt(BuildContext context, ThemeData theme) {
    final countdown = freezer.feedbackCountdownSeconds ?? 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
              const Text(
                'Ponto do Chocolate?',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5,
                  color: AppTheme.warningAmber,
                ),
              ),
              Text(
                '${countdown}s → OK Automático',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
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
                      minimumSize: const Size(0, 26),
                      backgroundColor: AppTheme.successGreen.withValues(
                        alpha: 0.28,
                      ),
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
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
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
                      minimumSize: const Size(0, 26),
                      backgroundColor: AppTheme.warningAmber.withValues(
                        alpha: 0.28,
                      ),
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
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.warningAmber,
                          fontFeatures: [FontFeature.tabularFigures()],
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
                      minimumSize: const Size(0, 26),
                      backgroundColor: AppTheme.primaryBlue.withValues(
                        alpha: 0.25,
                      ),
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
                          fontSize: 9,
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

  void _showDoorTimingConfigDialog(BuildContext context) {
    final unloadController = TextEditingController(
      text: freezer.unloadMinSeconds.toString(),
    );
    final reloadController = TextEditingController(
      text: freezer.reloadMinSeconds.toString(),
    );
    final targetMinController = TextEditingController(
      text: (freezer.calibratedBaseSeconds ~/ 60).toString(),
    );

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          title: Text(
            'Tempos da Porta — ${freezer.name}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Estes parâmetros definem como o sensor da porta identifica automaticamente verificação, retirada ou novo lote (também sincronizáveis pelo Supabase):',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const ValueKey('input_unload_seconds'),
                    controller: unloadController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tempo mín. Só Retirada (segundos)',
                      helperText:
                          'Abaixo disso com lote pronto = "Verificação / Ainda Mole"',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const ValueKey('input_reload_seconds'),
                    controller: reloadController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tempo mín. Retirou + Abasteceu (segundos)',
                      helperText:
                          'Acima disso = encerra o lote atual e já inicia nova contagem',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const ValueKey('input_target_minutes'),
                    controller: targetMinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tempo Alvo Base (minutos)',
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const ValueKey('save_door_timing_btn'),
              onPressed: () {
                final unload =
                    int.tryParse(unloadController.text.trim()) ??
                    freezer.unloadMinSeconds;
                final reload =
                    int.tryParse(reloadController.text.trim()) ??
                    freezer.reloadMinSeconds;
                final targetMin =
                    int.tryParse(targetMinController.text.trim()) ??
                    (freezer.calibratedBaseSeconds ~/ 60);
                viewModel.updateDoorTimingConfig(
                  freezer.freezerId,
                  unloadMinSeconds: unload,
                  reloadMinSeconds: reload,
                  targetDurationSeconds: targetMin * 60,
                );
                Navigator.of(ctx).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}

/// Painel limpo da Curva de Área com Marcador da Porta:
/// Exibe apenas a variação de temperatura desde o último evento da porta (+X.X °C pós-porta)
/// e o gráfico de área com a linha tracejada de referência.
final class FreezerThermalCurvePanel extends StatelessWidget {
  final FreezerLiveState freezer;

  const FreezerThermalCurvePanel({super.key, required this.freezer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final baseTemp = freezer.effectiveBaselineTemp;
    final delta = freezer.doorDeltaTemp;
    final isOpen = freezer.isDoorOpen;
    final hasDoorShift = delta.abs() >= 0.1 || freezer.doorOpenCount > 0;

    final Color curveColor;
    if (isOpen) {
      curveColor = colorScheme.error;
    } else if (hasDoorShift && (freezer.currentTemp - baseTemp) > 0.4) {
      curveColor = AppTheme.warningAmber;
    } else {
      curveColor = colorScheme.tertiary;
    }

    final sign = delta >= 0 ? '+' : '';
    final doorShiftLabel = hasDoorShift
        ? '$sign${delta.toStringAsFixed(1)} °C pós-porta'
        : '0.0 °C pós-porta';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.55),
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                        Icons.swap_vert_rounded,
                        size: 13,
                        color: hasDoorShift
                            ? curveColor
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        doorShiftLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: hasDoorShift
                              ? curveColor
                              : colorScheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (freezer.accumulatedPenaltySeconds > 0)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '+${freezer.accumulatedPenaltySeconds}s no alvo',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.warningAmber,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 28,
            child: CustomPaint(
              painter: _ThermalCurvePainter(
                history: freezer.temperatureHistory,
                doorTransitions: freezer.doorTransitions,
                baselineTemp: baseTemp,
                currentTemp: freezer.currentTemp,
                lineColor: curveColor,
                baselineColor: colorScheme.outline,
                doorOpenColor: colorScheme.error,
                doorCloseColor: AppTheme.successGreen,
              ),
            ),
          ),
        ],
      ),
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
  final Color baselineColor;
  final Color doorOpenColor;
  final Color doorCloseColor;

  const _ThermalCurvePainter({
    required this.history,
    required this.doorTransitions,
    required this.baselineTemp,
    required this.currentTemp,
    required this.lineColor,
    required this.baselineColor,
    required this.doorOpenColor,
    required this.doorCloseColor,
  });

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

    // Garante amplitude mínima de 2.0 °C para evitar ruído exagerado quando estável
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

    // 1. Linha tracejada horizontal da Temperatura de Referência (antes de abrir a porta)
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

    // 2. Constrói pontos (x, y) da curva de temperatura
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

    // 3. Preenchimento em gradiente sob a curva
    final fillPath = Path.from(curvePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.30),
          lineColor.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 4. Traço principal da curva térmica
    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(curvePath, strokePaint);

    // 5. Marcadores de eventos de abertura/fechamento de porta na janela de tempo
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
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), markerLinePaint);

          final dotPaint = Paint()..color = markerColor;
          canvas.drawCircle(Offset(x, y), 2.8, dotPaint);
        }
      }
    }

    // 6. Ponto luminoso da temperatura atual (extremidade direita)
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
        oldDelegate.history.length != history.length ||
        oldDelegate.doorTransitions.length != doorTransitions.length;
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
          return const AppEmptyState(
            icon: Icons.ac_unit_rounded,
            title: 'Nenhum freezer conectado',
            subtitle: 'Aguardando telemetria das câmaras frias no ESP32',
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < list.length; i++) ...[
              FreezerMonitoringCard(freezer: list[i], viewModel: viewModel),
              if (i < list.length - 1) const SizedBox(height: AppSpacing.xs),
            ],
          ],
        );
      },
    );
  }
}
