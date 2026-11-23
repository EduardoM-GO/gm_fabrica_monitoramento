import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_motion.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/app_states.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/status_badge.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/freezer_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_feedback_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_live_state.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_status_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/ui/view_models/freezer_monitoring_view_model.dart';

/// Card de monitoramento do Freezer otimizado para Kiosk Horizontal (SM-A055M/DS):
/// Hierarquia estrita de leitura:
/// 1. Tempo Atual / Tempo Previsto (MM:SS / MM:SS) + Status da Porta (Aberta / Fechada)
/// 2. Temperatura Atual (°C)
/// 3. Gráfico de Curva Térmica junto com o Tempo de Porta Aberta ao vivo (mostrando perda de temperatura)
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
    final isIdle = freezer.status == FreezerStatusEnum.idle;
    final hasOvertime = freezer.overtimeSeconds > 0;

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
      child: LayoutBuilder(
        builder: (context, cardConstraints) {
          final hasBoundedHeight = cardConstraints.maxHeight.isFinite;

          return AnimatedContainer(
            duration: AppMotion.durationStandard,
            curve: AppMotion.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            child: Column(
              mainAxisSize:
                  hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- 1. Topo: Nome do Equipamento Vinculado (Supabase) + Sensor + Status Forte de Porta + Ações Rápidas ---
                Row(
                  children: [
                    Icon(
                      Icons.ac_unit_rounded,
                      color: (isCooling || isReady || isOpen)
                          ? accentColor
                          : AppTheme.textMuted,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              freezer.displayHeaderName.toUpperCase(),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontFamily: AppTheme.fontHeading,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                fontSize: 11,
                                color: freezer.hasLinkedEquipment
                                    ? colorScheme.primary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isIdle && !isFeedback) ...[
                            InkWell(
                              key: ValueKey(
                                'freezer_mark_ready_${freezer.freezerId}',
                              ),
                              borderRadius: AppSpacing.borderRadiusXs,
                              onTap: () => viewModel.markBatchReadyAndCalibrate(
                                freezer.freezerId,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen.withValues(
                                    alpha: (isReady || hasOvertime || isOpen)
                                        ? 0.28
                                        : 0.14,
                                  ),
                                  borderRadius: AppSpacing.borderRadiusXs,
                                  border: Border.all(
                                    color: AppTheme.successGreen.withValues(
                                      alpha: (isReady || hasOvertime || isOpen)
                                          ? 0.65
                                          : 0.30,
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 12,
                                      color: AppTheme.successGreen,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Pronto',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.successGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          InkWell(
                            key: ValueKey(
                              'freezer_restart_${freezer.freezerId}',
                            ),
                            borderRadius: AppSpacing.borderRadiusXs,
                            onTap: () =>
                                viewModel.restartCycle(freezer.freezerId),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    size: 11,
                                    color: AppTheme.textMuted.withValues(
                                      alpha: 0.65,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Reiniciar',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textMuted.withValues(
                                        alpha: 0.65,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: IconButton(
                              key: ValueKey(
                                'freezer_config_${freezer.freezerId}',
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              tooltip:
                                  'Vincular equipamento e configurar tempos do sensor',
                              onPressed: () =>
                                  _showDoorTimingConfigDialog(context),
                              icon: Icon(
                                Icons.tune_rounded,
                                size: 13,
                                color: AppTheme.textMuted.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // --- 2. Faixa Principal: 1º Tempo Atual / Tempo Previsto (Hero #1) + 2º Temperatura (Hero #2) ---
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
                          child: _buildPrimaryTimeAndTempSection(
                            context,
                            theme,
                            accentColor,
                          ),
                        ),
                ),

                const SizedBox(height: 4),

                // --- 3. Gráfico Térmico junto com o Tempo de Porta Aberta (mostrando perda de temperatura) ---
                if (hasBoundedHeight)
                  Expanded(
                    child: FreezerThermalCurvePanel(
                      freezer: freezer,
                      expandGraph: true,
                    ),
                  )
                else
                  FreezerThermalCurvePanel(freezer: freezer),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrimaryTimeAndTempSection(
    BuildContext context,
    ThemeData theme,
    Color accentColor,
  ) {
    final colorScheme = theme.colorScheme;
    final isOpen = freezer.isDoorOpen;
    final isProbeOk = freezer.isSensorOk;
    final isReady = freezer.status == FreezerStatusEnum.ready;
    final isCooling = freezer.status == FreezerStatusEnum.cooling;
    final isIdle = freezer.status == FreezerStatusEnum.idle;
    final hasOvertime = freezer.overtimeSeconds > 0;

    final String statusLabel;
    final Color statusColor;

    if (isOpen) {
      statusLabel = 'PERDENDO TEMPERATURA';
      statusColor = colorScheme.error;
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

    final Color elapsedColor;
    if (isReady) {
      elapsedColor = AppTheme.successGreen;
    } else if (hasOvertime) {
      elapsedColor = AppTheme.warningAmber;
    } else if (isIdle) {
      elapsedColor = AppTheme.textSecondary;
    } else {
      elapsedColor = colorScheme.onSurface;
    }

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
                    Text.rich(
                      TextSpan(
                        text: freezer.elapsedFormatted,
                        style: TextStyle(
                          fontFamily: AppTheme.fontHeading,
                          fontSize: 30,
                          height: 1.0,
                          fontWeight: FontWeight.w900,
                          color: elapsedColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        children: [
                          TextSpan(
                            text: ' / ${freezer.targetFormatted}',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontBody,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                              fontFeatures: [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      key: ValueKey('freezer_time_${freezer.freezerId}'),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: isIdle ? 9.5 : 10,
                        fontWeight: isIdle ? FontWeight.w600 : FontWeight.w900,
                        letterSpacing: 0.3,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedValueText(
              value: isProbeOk
                  ? '${freezer.currentTemp.toStringAsFixed(1)} °C'
                  : '--.- °C',
              pulseScale: 1.03,
              style: TextStyle(
                fontFamily: AppTheme.fontHeading,
                fontSize: 20,
                height: 1.0,
                fontWeight: FontWeight.w900,
                color: !isProbeOk || isOpen
                    ? colorScheme.error
                    : isReady
                        ? AppTheme.successGreen
                        : colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
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
          backgroundColor: colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(4),
          duration: AppMotion.durationStandard,
          curve: AppMotion.easeOut,
        ),
      ],
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
    String? selectedEquipmentId = freezer.equipmentId;

    // Atualiza lista de equipamentos do Supabase ao abrir o diálogo
    viewModel.refreshEquipmentsAndBindings();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return SignalBuilder(
              builder: (_) {
                final equipments = viewModel.availableEquipments.value;
                final hasSelectedInList =
                    selectedEquipmentId != null &&
                    equipments.any((e) => e.id == selectedEquipmentId);
                final effectiveEquipmentId = hasSelectedInList
                    ? selectedEquipmentId
                    : null;

                return AlertDialog(
                  title: Text(
                    'Sensor ${freezer.sensorIndex} (${freezer.freezerId.toUpperCase()}) — ${freezer.name}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  content: SizedBox(
                    width: 400,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Vincule este sensor físico do ESP32 a um equipamento (Freezer) cadastrado no Supabase e configure os tempos de porta:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DropdownButtonFormField<String?>(
                            key: ValueKey(
                              'freezer_equipment_dropdown_${freezer.freezerId}',
                            ),
                            initialValue: effectiveEquipmentId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText:
                                  'Equipamento Vinculado (Supabase / Centros de Custo)',
                              isDense: true,
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest,
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Sem equipamento vinculado'),
                              ),
                              for (final eq in equipments)
                                DropdownMenuItem<String?>(
                                  value: eq.id,
                                  child: Text(
                                    eq.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (val) {
                              setDialogState(() {
                                selectedEquipmentId = val;
                              });
                            },
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
                              labelText:
                                  'Tempo mín. Retirou + Abasteceu (segundos)',
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

                        EquipmentModel? chosenEq;
                        if (selectedEquipmentId != null) {
                          chosenEq = equipments
                              .where((e) => e.id == selectedEquipmentId)
                              .firstOrNull;
                        }

                        viewModel.updateDoorTimingConfig(
                          freezer.freezerId,
                          unloadMinSeconds: unload,
                          reloadMinSeconds: reload,
                          targetDurationSeconds: targetMin * 60,
                          linkedEquipment: chosenEq,
                          updateEquipmentBinding: true,
                        );
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Salvar'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Painel da Curva de Área com Tempo de Porta Aberta ao vivo e Perda de Temperatura
final class FreezerThermalCurvePanel extends StatelessWidget {
  final FreezerLiveState freezer;
  final bool expandGraph;

  const FreezerThermalCurvePanel({
    super.key,
    required this.freezer,
    this.expandGraph = false,
  });

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
    final showHeaderRow =
        isOpen || hasDoorShift || freezer.accumulatedPenaltySeconds > 0;
    final doorShiftLabel = isOpen
        ? 'Perda: $sign${delta.toStringAsFixed(1)} °C ▲'
        : '$sign${delta.toStringAsFixed(1)} °C pós-porta';

    final graphWidget = CustomPaint(
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
    );

    return Column(
      mainAxisSize: expandGraph ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeaderRow) ...[
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
                      if (isOpen) ...[
                        Icon(
                          Icons.timer_outlined,
                          size: 11,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'ABERTA HÁ ${freezer.currentDoorOpenFormatted}',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.error,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (isOpen || hasDoorShift) ...[
                        Icon(
                          isOpen
                              ? Icons.trending_up_rounded
                              : Icons.swap_vert_rounded,
                          size: 12,
                          color: curveColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          doorShiftLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: curveColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
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
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warningAmber.withValues(alpha: 0.8),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
        ],
        if (expandGraph)
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 18),
              child: graphWidget,
            ),
          )
        else
          SizedBox(
            height: 24,
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

    final strokePaint = Paint()
      ..color = lineColor
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

        return LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.maxHeight.isFinite;

            return Column(
              mainAxisSize:
                  hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < list.length; i++) ...[
                  if (hasBoundedHeight)
                    Expanded(
                      child: FreezerMonitoringCard(
                        freezer: list[i],
                        viewModel: viewModel,
                      ),
                    )
                  else
                    FreezerMonitoringCard(
                      freezer: list[i],
                      viewModel: viewModel,
                    ),
                  if (i < list.length - 1) const SizedBox(height: 6),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
