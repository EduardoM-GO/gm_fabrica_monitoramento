import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_formatter.dart';
import '../../data/models/freezer_view_data.dart';
import '../../logic/monitoring/monitoring_cubit.dart';
import '../../logic/settings/settings_cubit.dart';
import '../../logic/settings/settings_state.dart';
import 'temperature_chart.dart';

class FreezerCard extends StatelessWidget {
  final FreezerViewData freezer;
  final int freezerNumber;

  const FreezerCard({
    super.key,
    required this.freezer,
    required this.freezerNumber,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = freezer.isDoorOpen;
    final isProbeOk = freezer.isProbeOk;
    final alert = freezer.alertLevel;
    final duration = freezer.doorDuration;
    final delta = freezer.temperatureDelta;

    // Determine colors and borders based on alert level & door status
    Color borderColor;
    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    if (!isProbeOk) {
      borderColor = AppTheme.dangerRed;
      statusColor = AppTheme.dangerRed;
      statusTitle = 'FALHA DE SONDA';
      statusIcon = Icons.warning_rounded;
    } else if (isOpen) {
      if (alert.isCritical) {
        borderColor = AppTheme.dangerRed;
        statusColor = AppTheme.dangerRed;
        statusTitle = 'PORTA ABERTA (CRÍTICO)';
        statusIcon = Icons.error_rounded;
      } else if (alert.isWarning) {
        borderColor = AppTheme.warningAmber;
        statusColor = AppTheme.warningAmber;
        statusTitle = 'PORTA ABERTA (ATENÇÃO)';
        statusIcon = Icons.warning_amber_rounded;
      } else {
        borderColor = AppTheme.warningAmber;
        statusColor = AppTheme.warningAmber;
        statusTitle = 'PORTA ABERTA';
        statusIcon = Icons.meeting_room_outlined;
      }
    } else {
      borderColor = AppTheme.surfaceBorder;
      statusColor = AppTheme.successGreen;
      statusTitle = 'PORTA FECHADA';
      statusIcon = Icons.door_front_door_rounded;
    }

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        return Card(
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: alert.isCritical ? AppTheme.dangerRed : borderColor,
              width: alert.isCritical ? 2.5 : 1.2,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: alert.isCritical
                  ? [
                      BoxShadow(
                        color: AppTheme.dangerRed.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Name and Probe Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.ac_unit_rounded,
                        color: AppTheme.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            freezer.name.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            freezerNumber == 1
                                ? 'Câmara de Resfriamento'
                                : 'Túnel de Congelamento',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Probe status chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isProbeOk
                            ? AppTheme.successGreen.withValues(alpha: 0.12)
                            : AppTheme.dangerRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isProbeOk
                              ? AppTheme.successGreen.withValues(alpha: 0.4)
                              : AppTheme.dangerRed.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isProbeOk
                                ? Icons.check_circle_outline_rounded
                                : Icons.sensors_off_rounded,
                            size: 13,
                            color: isProbeOk
                                ? AppTheme.successGreen
                                : AppTheme.dangerRed,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isProbeOk ? 'Sonda OK' : 'Sonda Falhou',
                            style: TextStyle(
                              color: isProbeOk
                                  ? AppTheme.successGreen
                                  : AppTheme.dangerRed,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Probe Failure Alert Banner (when ok == 0)
                if (!isProbeOk) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.dangerRed.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.dangerRed,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ATENÇÃO: Sonda térmica desconectada ou danificada!',
                            style: TextStyle(
                              color: AppTheme.dangerRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Temperature Readout & Door Status Banner
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Temperature Number
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TEMPERATURA ATUAL',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isProbeOk
                                ? '${freezer.currentTemp.toStringAsFixed(1)} °C'
                                : '--.- °C',
                            style: TextStyle(
                              color: isProbeOk
                                  ? AppTheme.textPrimary
                                  : AppTheme.textMuted,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Door Status Badge & Timer
                    Expanded(
                      flex: 6,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  statusIcon,
                                  color: statusColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    statusTitle,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isOpen
                                  ? 'Aberta há: ${TimeFormatter.formatDuration(duration)}'
                                  : 'Fechada há: ${TimeFormatter.formatDuration(duration)}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Delta temperature
                            Row(
                              children: [
                                Icon(
                                  isOpen ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                  size: 14,
                                  color: isOpen ? AppTheme.dangerRed : AppTheme.primaryBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOpen
                                      ? 'Perda: ${TimeFormatter.formatTemperatureDelta(delta)}'
                                      : 'Recuperado: ${TimeFormatter.formatTemperatureDelta(delta)}',
                                  style: TextStyle(
                                    color: isOpen ? AppTheme.dangerRed : AppTheme.primaryBlue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Mini Trend Line Chart
                const Text(
                  'HISTÓRICO TÉRMICO RECENTE',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                TemperatureChart(
                  history: freezer.history,
                  isCoolingChamber: freezerNumber == 1,
                ),

                const SizedBox(height: 14),

                // Simulator interactive controls (for instant testing)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isOpen
                              ? AppTheme.successGreen
                              : AppTheme.warningAmber,
                          side: BorderSide(
                            color: (isOpen
                                    ? AppTheme.successGreen
                                    : AppTheme.warningAmber)
                                .withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: Icon(
                          isOpen
                              ? Icons.door_back_door_outlined
                              : Icons.door_sliding_outlined,
                          size: 16,
                        ),
                        label: Text(
                          isOpen ? 'Fechar Porta' : 'Abrir Porta',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          context
                              .read<MonitoringCubit>()
                              .toggleSimulatorDoor(freezerNumber);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isProbeOk
                            ? AppTheme.dangerRed
                            : AppTheme.successGreen,
                        side: BorderSide(
                          color: (isProbeOk
                                  ? AppTheme.dangerRed
                                  : AppTheme.successGreen)
                              .withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 10,
                        ),
                      ),
                      icon: Icon(
                        isProbeOk
                            ? Icons.sensors_off_rounded
                            : Icons.sensors_rounded,
                        size: 15,
                      ),
                      label: Text(
                        isProbeOk ? 'Falhar Sonda' : 'Restaurar',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        context
                            .read<MonitoringCubit>()
                            .toggleSimulatorProbe(freezerNumber);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

