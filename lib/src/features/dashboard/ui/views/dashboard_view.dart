import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_breakpoints.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/status_badge.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/enum/ws_connection_state_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/ui/view_models/freezer_monitoring_view_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/ui/views/freezer_monitoring_card.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/ui/view_models/egg_count_view_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/ui/views/egg_count_card.dart';
import 'package:gm_fabrica_monitoramento/src/features/settings/ui/view_models/settings_view_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/settings/ui/views/settings_dialog.dart';
import 'package:provider/provider.dart';
import 'package:signals/signals_flutter.dart';

/// Painel principal Kiosk Zero-Navegação (60/40) para chão de fábrica.
/// Segue estritamente Material Design 3, superfícies tonais e alta densidade visual.
final class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final eggViewModel = context.read<EggCountViewModel>();
    final freezerViewModel = context.read<FreezerMonitoringViewModel>();
    final settingsViewModel = context.read<SettingsViewModel>();

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = AppBreakpoints.isLandscape(context);
            final isWideEnough =
                constraints.maxWidth >= AppBreakpoints.compactMax;
            final minViewportHeight =
                (constraints.maxHeight - (AppSpacing.xs * 2)).clamp(
                  0.0,
                  double.infinity,
                );

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: isLandscape && isWideEnough
                      ? minViewportHeight
                      : 0.0,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopKioskStatusStrip(
                        eggViewModel: eggViewModel,
                        freezerViewModel: freezerViewModel,
                        settingsViewModel: settingsViewModel,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (isLandscape && isWideEnough)
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Zona Esquerda (60%): Embalagem e Contagem de Ovos (0ms)
                              Expanded(
                                flex: 6,
                                child: EggCountCard(viewModel: eggViewModel),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              // Zona Direita (40%): Monitoramento Adaptativo dos 2 Freezers
                              Expanded(
                                flex: 4,
                                child: FreezerMonitoringZone(
                                  viewModel: freezerViewModel,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        EggCountCard(viewModel: eggViewModel),
                        const SizedBox(height: AppSpacing.xs),
                        FreezerMonitoringZone(viewModel: freezerViewModel),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

final class _TopKioskStatusStrip extends StatelessWidget {
  final EggCountViewModel eggViewModel;
  final FreezerMonitoringViewModel freezerViewModel;
  final SettingsViewModel settingsViewModel;

  const _TopKioskStatusStrip({
    required this.eggViewModel,
    required this.freezerViewModel,
    required this.settingsViewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SignalBuilder(
      builder: (context) {
        final room = eggViewModel.roomTelemetry.value;
        final connState = settingsViewModel.connectionState.value;
        final host = settingsViewModel.espHost.value;
        final isDiscovering = settingsViewModel.isDiscovering.value;
        final hasDoorAlarm = freezerViewModel.hasDoorAlarm.value;

        final (Color statusColor, String statusText) = switch (connState) {
          WsConnectionStateEnum.connected => (
            AppTheme.successGreen,
            'ESP32 Online ($host)',
          ),
          WsConnectionStateEnum.connecting => (
            AppTheme.warningAmber,
            'Conectando ($host)...',
          ),
          WsConnectionStateEnum.reconnecting => (
            AppTheme.warningAmber,
            isDiscovering ? 'Auto-Discovery na Rede...' : 'Reconectando...',
          ),
          WsConnectionStateEnum.disconnected => (
            AppTheme.dangerRed,
            'ESP32 Offline ($host)',
          ),
        };

        return Card.filled(
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
            side: BorderSide(
              color: hasDoorAlarm
                  ? colorScheme.error.withValues(alpha: 0.7)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            child: Row(
              children: [
                // Identificação da Linha de Produção (Paleta Cacau & Ouro)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: AppSpacing.borderRadiusXs,
                        ),
                        child: Icon(
                          Icons.factory_rounded,
                          size: 14,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          'G&M CHOCOLATES',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontFamily: AppTheme.fontHeading,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                if (hasDoorAlarm) ...[
                  const StatusBadge(
                    label: 'ALARME TÉRMICO',
                    color: AppTheme.dangerRed,
                    icon: Icons.warning_amber_rounded,
                    compact: true,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],

                // Pill Tonal de Clima da Sala 4x4m
                Flexible(
                  child: Card.filled(
                    color: colorScheme.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 4,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.thermostat_rounded,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              room != null
                                  ? 'Sala: ${room.temp.toStringAsFixed(1)} °C • ${room.humidity.toStringAsFixed(0)}% UR'
                                  : 'Sala: --.- °C • --% UR',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.xs),

                // Semáforo WebSocket + Ação Tonal de Configurações
                Flexible(
                  child: InkWell(
                    borderRadius: AppSpacing.borderRadiusSm,
                    onTap: () => _openSettings(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: StatusBadge(
                            label: statusText,
                            color: statusColor,
                            showDot: true,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          padding: EdgeInsets.zero,
                          iconSize: 15,
                          tooltip: 'Configurações do Kiosk & ESP32',
                          onPressed: () => _openSettings(context),
                          icon: const Icon(Icons.settings_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSettings(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => SettingsDialog(
        settingsViewModel: settingsViewModel,
        freezerViewModel: freezerViewModel,
      ),
    );
  }
}

typedef DashboardScreen = DashboardView;
