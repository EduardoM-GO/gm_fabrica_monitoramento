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

            // Modo Kiosk Horizontal (ex: Samsung Galaxy A05 SM-A055M/DS ~800x360 dp):
            // 100% fixo na tela sem scroll, proporção 52% Contagem / 48% Freezers.
            if (isLandscape && isWideEnough) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopKioskStatusStrip(
                      eggViewModel: eggViewModel,
                      freezerViewModel: freezerViewModel,
                      settingsViewModel: settingsViewModel,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Zona Esquerda (52%): Embalagem e Contagem de Ovos (0ms)
                          Expanded(
                            flex: 52,
                            child: EggCountCard(viewModel: eggViewModel),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          // Zona Direita (48%): Monitoramento Adaptativo dos 2 Freezers
                          Expanded(
                            flex: 48,
                            child: FreezerMonitoringZone(
                              viewModel: freezerViewModel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopKioskStatusStrip(
                    eggViewModel: eggViewModel,
                    freezerViewModel: freezerViewModel,
                    settingsViewModel: settingsViewModel,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  EggCountCard(viewModel: eggViewModel),
                  const SizedBox(height: AppSpacing.xs),
                  FreezerMonitoringZone(viewModel: freezerViewModel),
                ],
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
            'Online',
          ),
          WsConnectionStateEnum.connecting => (
            AppTheme.warningAmber,
            'Conectando ($host)...',
          ),
          WsConnectionStateEnum.reconnecting => (
            AppTheme.warningAmber,
            isDiscovering ? 'Buscando ESP32...' : 'Reconectando...',
          ),
          WsConnectionStateEnum.disconnected => (
            AppTheme.dangerRed,
            'Offline ($host)',
          ),
        };

        final isHealthy =
            connState == WsConnectionStateEnum.connected && !hasDoorAlarm;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: hasDoorAlarm
                ? colorScheme.errorContainer.withValues(alpha: 0.35)
                : Colors.transparent,
            borderRadius: AppSpacing.borderRadiusSm,
            border: hasDoorAlarm
                ? Border.all(color: colorScheme.error.withValues(alpha: 0.7))
                : null,
          ),
          child: Row(
            children: [
              // Identificação discreta da linha (Tier 3 — não compete com o produto ativo)
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.factory_rounded,
                      size: 12,
                      color: AppTheme.textMuted.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'G&M CHOCOLATES',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontFamily: AppTheme.fontHeading,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppTheme.textMuted,
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

              // Clima da Sala (Tier 3 — informação ambiental tímida)
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thermostat_rounded,
                        size: 12,
                        color: AppTheme.textMuted.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        room != null
                            ? 'Sala: ${room.temp.toStringAsFixed(1)} °C • ${room.humidity.toStringAsFixed(0)}% UR'
                            : 'Sala: --.- °C • --% UR',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Semáforo WebSocket + Ação Tímida de Configurações
              Flexible(
                child: InkWell(
                  borderRadius: AppSpacing.borderRadiusXs,
                  onTap: () => _openSettings(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: StatusBadge(
                          label: statusText,
                          color: statusColor,
                          showDot: true,
                          compact: true,
                          subtle: isHealthy,
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          iconSize: 14,
                          color: AppTheme.textMuted.withValues(alpha: 0.7),
                          tooltip: 'Configurações do Kiosk & ESP32',
                          onPressed: () => _openSettings(context),
                          icon: const Icon(Icons.settings_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
