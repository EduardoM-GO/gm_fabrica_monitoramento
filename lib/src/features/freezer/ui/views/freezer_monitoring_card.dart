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

/// Card de monitoramento do Freezer otimizado para Kiosk Horizontal (SM-A055M/DS)
/// com arquitetura de **Micro-States (atualização direcionada por campo)**:
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

        // O conteúdo interno do card é construído uma única vez e passado como `child`
        // para que mudanças na borda/cor do Card jamais reconstruam a árvore interna.
        final cardBody = Padding(
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
              // --- 1. Topo: Nome + Porta + Ações Rápidas (Cada um com seu próprio Micro-State) ---
              _buildHeaderRow(context, theme, colorScheme, item),

              const SizedBox(height: 4),

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
                            child: _buildFeedbackPrompt(context, theme, item),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('panel_timer_live'),
                            child: _buildPrimaryTimeAndTempSection(
                              context,
                              theme,
                              colorScheme,
                              item,
                            ),
                          ),
                  );
                },
              ),

              const SizedBox(height: 4),

              // --- 3. Gráfico Térmico junto com o Tempo de Porta Aberta (isolado em micro-states térmicos) ---
              if (hasBoundedHeight)
                Expanded(
                  child: FreezerThermalCurvePanel(
                    itemSignals: item,
                    expandGraph: true,
                  ),
                )
              else
                FreezerThermalCurvePanel(itemSignals: item),
            ],
          ),
        );

        // Micro-state da casca do Card: só reconstrói a decoração quando status, isDoorOpen ou isSensorOk mudam
        return SignalBuilder(
          builder: (context) {
            final status = item.status.value;
            final isOpen = item.isDoorOpen.value;
            final isProbeOk = item.isSensorOk.value;
            final isReady = status == FreezerStatusEnum.ready;
            final isFeedback = status == FreezerStatusEnum.feedbackPending;
            final isCooling = status == FreezerStatusEnum.cooling;

            final Color cardBgColor;
            final Color borderColor;

            if (!isProbeOk || isOpen) {
              cardBgColor = colorScheme.errorContainer.withValues(alpha: 0.30);
              borderColor = colorScheme.error;
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

            return Card.outlined(
              color: cardBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusLg,
                side: BorderSide(
                  color: borderColor,
                  width: (isReady || isOpen || !isProbeOk) ? 2.0 : 1.2,
                ),
              ),
              child: cardBody,
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
    FreezerItemSignals item,
  ) {
    return Row(
      children: [
        // Micro-state do ícone de gelo
        SignalBuilder(
          builder: (context) {
            final status = item.status.value;
            final isOpen = item.isDoorOpen.value;
            final isProbeOk = item.isSensorOk.value;
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
              Icons.ac_unit_rounded,
              color: isActive ? accentColor : AppTheme.textMuted,
              size: 13,
            );
          },
        ),
        const SizedBox(width: 4),
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
                        fontSize: 11,
                        color: hasLinked
                            ? colorScheme.primary
                            : AppTheme.textSecondary,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                // Micro-state do Badge de Porta (só reconstrói quando isDoorOpen muda)
                SignalBuilder(
                  builder: (context) {
                    final isOpen = item.isDoorOpen.value;
                    return StatusBadge(
                      label: isOpen ? 'PORTA ABERTA' : 'PORTA FECHADA',
                      icon: isOpen
                          ? Icons.sensor_door_outlined
                          : Icons.door_front_door_rounded,
                      color: isOpen ? colorScheme.error : AppTheme.successGreen,
                      compact: true,
                      subtle: false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),

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
                    padding: const EdgeInsets.only(right: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('freezer_mark_ready_${item.freezerId}'),
                        borderRadius: AppSpacing.borderRadiusXs,
                        onTap: () => viewModel.markBatchReadyAndCalibrate(
                          item.freezerId,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 13,
                                color: AppTheme.successGreen,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Pronto',
                                style: TextStyle(
                                  fontSize: 10.5,
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
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('freezer_restart_${item.freezerId}'),
                  borderRadius: AppSpacing.borderRadiusXs,
                  onTap: () => viewModel.restartCycle(item.freezerId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 13,
                          color: AppTheme.textMuted.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Reiniciar',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              // Botão Configurar estático — NUNCA sofre rebuild durante ticks do cronômetro ou telemetria!
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('freezer_config_${item.freezerId}'),
                  borderRadius: AppSpacing.borderRadiusXs,
                  onTap: () => _showDoorTimingConfigDialog(context, item),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 15,
                      color: AppTheme.textMuted.withValues(alpha: 0.75),
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
    FreezerItemSignals item,
  ) {
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

                        final Color elapsedColor;
                        if (status == FreezerStatusEnum.ready) {
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
                              fontSize: 30,
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
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontBody,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                          key: ValueKey('freezer_time_${item.freezerId}'),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    // Micro-state 2: Rótulo de status operacional (só reconstrói quando status ou porta mudam)
                    SignalBuilder(
                      builder: (context) {
                        final isOpen = item.isDoorOpen.value;
                        final status = item.status.value;
                        final isReady = status == FreezerStatusEnum.ready;
                        final isCooling = status == FreezerStatusEnum.cooling;
                        final isIdle = status == FreezerStatusEnum.idle;

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

                        return Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: isIdle ? 9.5 : 10,
                            fontWeight: isIdle
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
            const SizedBox(width: 8),
            // Micro-state 3: Temperatura atual (°C) — só reconstrói quando a temperatura muda em 0.1 °C
            SignalBuilder(
              builder: (context) {
                final fmtTemp = item.formattedTemp.value;
                final isProbeOk = item.isSensorOk.value;
                final isOpen = item.isDoorOpen.value;
                final isReady = item.status.value == FreezerStatusEnum.ready;

                return AnimatedValueText(
                  value: fmtTemp,
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
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Micro-state 4: Barra de progresso do ciclo
        SignalBuilder(
          builder: (context) {
            final progress = item.progress.value;
            final isReady = item.status.value == FreezerStatusEnum.ready;
            final isOpen = item.isDoorOpen.value;

            return SmoothProgressBar(
              value: progress,
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
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeedbackPrompt(
    BuildContext context,
    ThemeData theme,
    FreezerItemSignals item,
  ) {
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
              // Micro-state do countdown de 30s: atualiza apenas este Text, mantendo os 3 botões abaixo 100% estáticos!
              SignalBuilder(
                builder: (context) {
                  final countdown = item.feedbackCountdownSeconds.value;
                  return Text(
                    '${countdown}s → OK Automático',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.warningAmber,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  );
                },
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
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 32),
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
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'No Ponto',
                        style: TextStyle(
                          fontSize: 10,
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
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 32),
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
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Ainda Mole (+3m)',
                        style: TextStyle(
                          fontSize: 9.5,
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
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 32),
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
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Muito Gelado',
                        style: TextStyle(
                          fontSize: 9.5,
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
    final unloadController = TextEditingController(
      text: item.unloadMinSeconds.value.toString(),
    );
    final reloadController = TextEditingController(
      text: item.reloadMinSeconds.value.toString(),
    );
    final targetMinController = TextEditingController(
      text: (item.calibratedBaseSeconds.value ~/ 60).toString(),
    );
    String? selectedEquipmentId = item.equipmentId.value;

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
                    'Sensor ${item.sensorIndex.value} (${item.freezerId.toUpperCase()}) — ${item.name.value}',
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
                              'freezer_equipment_dropdown_${item.freezerId}',
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
                            item.unloadMinSeconds.value;
                        final reload =
                            int.tryParse(reloadController.text.trim()) ??
                            item.reloadMinSeconds.value;
                        final targetMin =
                            int.tryParse(targetMinController.text.trim()) ??
                            (item.calibratedBaseSeconds.value ~/ 60);

                        EquipmentModel? chosenEq;
                        if (selectedEquipmentId != null) {
                          chosenEq = equipments
                              .where((e) => e.id == selectedEquipmentId)
                              .firstOrNull;
                        }

                        viewModel.updateDoorTimingConfig(
                          item.freezerId,
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

/// Painel da Curva de Área com Tempo de Porta Aberta ao vivo e Perda de Temperatura.
/// Isolado em 2 micro-states independentes:
/// 1) Cabeçalho de tempo de porta aberta / ΔT / penalidade
/// 2) Gráfico [CustomPaint] (só repinta quando chega amostra térmica ou transição de porta, nunca no tick de 1s do relógio!)
final class FreezerThermalCurvePanel extends StatelessWidget {
  final FreezerLiveState? freezer;
  final FreezerItemSignals? itemSignals;
  final bool expandGraph;

  const FreezerThermalCurvePanel({
    super.key,
    this.freezer,
    this.itemSignals,
    this.expandGraph = false,
  }) : assert(
         freezer != null || itemSignals != null,
         'Informe freezer ou itemSignals',
       );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final item = itemSignals ?? FreezerItemSignals(freezer!);

    final graphWidget = RepaintBoundary(
      child: SignalBuilder(
        builder: (context) {
          final history = item.temperatureHistory.value;
          final doorTransitions = item.doorTransitions.value;
          final baseTemp = item.effectiveBaselineTemp.value;
          final currentTemp = item.currentTemp.value;
          final isOpen = item.isDoorOpen.value;
          final delta = item.doorDeltaTemp.value;
          final hasDoorShift =
              delta.abs() >= 0.1 || item.doorOpenCount.value > 0;

          final Color curveColor;
          if (isOpen) {
            curveColor = colorScheme.error;
          } else if (hasDoorShift && (currentTemp - baseTemp) > 0.4) {
            curveColor = AppTheme.warningAmber;
          } else {
            curveColor = colorScheme.tertiary;
          }

          return CustomPaint(
            painter: _ThermalCurvePainter(
              history: history,
              doorTransitions: doorTransitions,
              baselineTemp: baseTemp,
              currentTemp: currentTemp,
              lineColor: curveColor,
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
        // Micro-state do cabeçalho de porta aberta e perda térmica
        SignalBuilder(
          builder: (context) {
            final isOpen = item.isDoorOpen.value;
            final delta = item.doorDeltaTemp.value;
            final doorOpenCount = item.doorOpenCount.value;
            final penaltySec = item.accumulatedPenaltySeconds.value;
            final baseTemp = item.effectiveBaselineTemp.value;
            final currentTemp = item.currentTemp.value;
            final hasDoorShift = delta.abs() >= 0.1 || doorOpenCount > 0;
            final showHeaderRow = isOpen || hasDoorShift || penaltySec > 0;

            if (!showHeaderRow) {
              return const SizedBox.shrink();
            }

            final Color curveColor;
            if (isOpen) {
              curveColor = colorScheme.error;
            } else if (hasDoorShift && (currentTemp - baseTemp) > 0.4) {
              curveColor = AppTheme.warningAmber;
            } else {
              curveColor = colorScheme.tertiary;
            }

            final sign = delta >= 0 ? '+' : '';
            final doorShiftLabel = isOpen
                ? 'Perda: $sign${delta.toStringAsFixed(1)} °C ▲'
                : '$sign${delta.toStringAsFixed(1)} °C pós-porta';

            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
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
                              size: 11,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 3),
                            // Micro-state aninhado exclusivamente para os segundos da porta aberta
                            SignalBuilder(
                              builder: (context) {
                                return Text(
                                  'ABERTA HÁ ${item.currentDoorOpenFormatted.value}',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: colorScheme.error,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                );
                              },
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
                  if (penaltySec > 0)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '+${penaltySec}s no alvo',
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
            );
          },
        ),
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
            if (hasF1 && hasF2) const SizedBox(height: 6),
            if (hasF2)
              if (hasBoundedHeight) Expanded(child: card2) else card2,
          ],
        );
      },
    );
  }
}
