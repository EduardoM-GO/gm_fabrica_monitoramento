import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_formatter.dart';
import '../../data/services/websocket_service.dart';
import '../../logic/production/production_cubit.dart';
import '../../logic/production/production_state.dart';
import '../../logic/settings/settings_cubit.dart';
import '../../logic/settings/settings_state.dart';
import 'settings_dialog.dart';

class StatusHeader extends StatelessWidget {
  const StatusHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        return BlocBuilder<ProductionCubit, ProductionState>(
          builder: (context, state) {
            final status = state.connectionStatus;
            final isConnected = status == ConnectionStatus.connected;
            final isReconnecting = status == ConnectionStatus.reconnecting ||
                status == ConnectionStatus.connecting;

            Color statusColor;
            String statusText;
            if (isConnected) {
              statusColor = AppTheme.successGreen;
              statusText = settings.isMockEnabled ? 'Simulador' : 'Online';
            } else if (isReconnecting) {
              statusColor = AppTheme.warningAmber;
              statusText = 'Conectando...';
            } else {
              statusColor = AppTheme.dangerRed;
              statusText = 'Offline';
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTight = constraints.maxWidth < 500;

                  return Row(
                    children: [
                      // Factory branding & icon
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.precision_manufacturing_rounded,
                          color: AppTheme.primaryBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Title & Uptime column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              children: [
                                const Text(
                                  'GM FÁBRICA',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'TELEMETRIA',
                                    style: TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 10,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Uptime: ${TimeFormatter.formatUptime(state.uptimeMs)}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      fontFeatures: [
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

                      // Status Badge
                      Tooltip(
                        message: state.connectionErrorMessage ??
                            (isConnected
                                ? 'Conectado a ${settings.wsUrl}'
                                : 'Tentando conectar a ${settings.wsUrl}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.4),
                            ),
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
                              const SizedBox(width: 5),
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

                      const SizedBox(width: 6),

                      // Quick Mock Toggle (compact on tight widths)
                      if (!isTight) ...[
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(
                            settings.isMockEnabled
                                ? Icons.developer_mode_rounded
                                : Icons.wifi_tethering_rounded,
                            size: 13,
                            color: settings.isMockEnabled
                                ? AppTheme.eggOrange
                                : AppTheme.textMuted,
                          ),
                          label: Text(
                            settings.isMockEnabled ? 'Simulador' : 'Hardware',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: settings.isMockEnabled
                                  ? AppTheme.eggOrange
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          backgroundColor: settings.isMockEnabled
                              ? AppTheme.eggOrange.withValues(alpha: 0.15)
                              : colorScheme.surfaceContainerHighest,
                          side: BorderSide(
                            color: settings.isMockEnabled
                                ? AppTheme.eggOrange.withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                          onPressed: () {
                            context
                                .read<SettingsCubit>()
                                .toggleMock(!settings.isMockEnabled);
                          },
                        ),
                        const SizedBox(width: 4),
                      ],

                      // Settings button
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: AppTheme.textSecondary,
                          size: 19,
                        ),
                        tooltip: 'Configurações de Conexão e Alertas',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const SettingsDialog(),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
