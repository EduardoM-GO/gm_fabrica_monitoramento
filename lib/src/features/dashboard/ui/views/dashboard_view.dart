import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_breakpoints.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/kiosk_clock_display.dart';
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

/// Painel principal Kiosk Zero-Navegação (50/50 em Tablet 11" Lenovo Idea Tab TB336FU,
/// 52/48 em Kiosk Compacto) para chão de fábrica.
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
            final isTablet = AppBreakpoints.isTabletKiosk(context);

            // Modo Kiosk Horizontal (Lenovo Idea Tab TB336FU 11" 2560x1600 16:10 ou Galaxy A05 ~800x360 dp):
            // 100% fixo na tela sem scroll, aproveitando toda a altura 16:10 do tablet.
            if (isLandscape && isWideEnough) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? AppSpacing.md : AppSpacing.xs,
                  vertical: isTablet ? AppSpacing.xs : 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopKioskStatusStrip(
                      eggViewModel: eggViewModel,
                      freezerViewModel: freezerViewModel,
                      settingsViewModel: settingsViewModel,
                    ),
                    SizedBox(height: isTablet ? AppSpacing.xs : 4),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Zona Esquerda: Embalagem e Contagem de Ovos (0ms)
                          Expanded(
                            flex: isTablet ? 50 : 52,
                            child: EggCountCard(viewModel: eggViewModel),
                          ),
                          SizedBox(
                            width: isTablet ? AppSpacing.sm : AppSpacing.xs,
                          ),
                          // Zona Direita: Monitoramento Adaptativo dos 2 Freezers
                          Expanded(
                            flex: isTablet ? 50 : 48,
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

            // Modo Retrato em Tablet (ex.: 800x1280 dp no TB336FU): preenche 100% da altura sem scroll se houver espaço vertical suficiente
            if (!isLandscape && constraints.maxHeight >= 900) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopKioskStatusStrip(
                      eggViewModel: eggViewModel,
                      freezerViewModel: freezerViewModel,
                      settingsViewModel: settingsViewModel,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      flex: 46,
                      child: EggCountCard(viewModel: eggViewModel),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      flex: 54,
                      child: FreezerMonitoringZone(viewModel: freezerViewModel),
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
    final isTablet = AppBreakpoints.isTabletKiosk(context);

    return SignalBuilder(
      builder: (context) {
        final hasDoorAlarm = freezerViewModel.hasDoorAlarm.value;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? AppSpacing.sm : AppSpacing.xs,
            vertical: isTablet ? 6 : 2,
          ),
          decoration: BoxDecoration(
            color: hasDoorAlarm
                ? colorScheme.errorContainer.withValues(alpha: 0.35)
                : (isTablet
                      ? colorScheme.surfaceContainerLow
                      : Colors.transparent),
            borderRadius: AppSpacing.borderRadiusSm,
            border: hasDoorAlarm
                ? Border.all(color: colorScheme.error.withValues(alpha: 0.7))
                : (isTablet
                      ? Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        )
                      : null),
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
                      size: isTablet ? 16 : 12,
                      color: AppTheme.textMuted.withValues(alpha: 0.85),
                    ),
                    SizedBox(width: isTablet ? 8 : 5),
                    Flexible(
                      child: Text(
                        'G&M CHOCOLATES',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontFamily: AppTheme.fontHeading,
                          fontSize: isTablet ? 13 : 10.5,
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
                SizedBox(width: isTablet ? AppSpacing.sm : AppSpacing.xs),
              ],

              // Data e Hora atual em tempo real (evita arrastar barra do sistema em modo Kiosk)
              const Flexible(
                child: KioskClockDisplay(),
              ),

              SizedBox(width: isTablet ? AppSpacing.md : AppSpacing.sm),

              // Clima da Sala isolado em seu próprio micro-state textual (`roomSummaryText`)
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thermostat_rounded,
                        size: isTablet ? 16 : 12,
                        color: AppTheme.textMuted.withValues(alpha: 0.85),
                      ),
                      SizedBox(width: isTablet ? 5 : 3),
                      SignalBuilder(
                        builder: (context) {
                          final isClimateAlert =
                              eggViewModel.isRoomClimateAlert.value;
                          return Text(
                            eggViewModel.roomSummaryText.value,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: isTablet ? 13.5 : 11,
                              fontWeight: isClimateAlert
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: isClimateAlert
                                  ? AppTheme.warningAmber
                                  : (isTablet
                                        ? AppTheme.textSecondary
                                        : AppTheme.textMuted),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: isTablet ? AppSpacing.md : AppSpacing.sm),

              // Semáforo WebSocket + Ação de Configurações (um único InkWell com hitbox amplo e sem IconButton aninhado competindo pelo toque)
              Flexible(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: AppSpacing.borderRadiusXs,
                    onTap: () => _openSettings(context),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 10 : 6,
                        vertical: isTablet ? 6 : 4,
                      ),
                      child: SignalBuilder(
                        builder: (context) {
                          final connState =
                              settingsViewModel.connectionState.value;
                          final host = settingsViewModel.espHost.value;
                          final isDiscovering =
                              settingsViewModel.isDiscovering.value;

                          final (Color statusColor, String statusText) =
                              switch (connState) {
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
                                  isDiscovering
                                      ? 'Buscando ESP32...'
                                      : 'Reconectando...',
                                ),
                                WsConnectionStateEnum.disconnected => (
                                  AppTheme.dangerRed,
                                  'Offline ($host)',
                                ),
                              };

                          final isHealthy =
                              connState == WsConnectionStateEnum.connected &&
                              !hasDoorAlarm;

                          return Row(
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
                              SizedBox(width: isTablet ? 8 : 6),
                              Icon(
                                Icons.settings_rounded,
                                size: isTablet ? 20 : 16,
                                color: AppTheme.textMuted.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
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
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SettingsDialog(
          settingsViewModel: settingsViewModel,
          freezerViewModel: freezerViewModel,
          eggViewModel: eggViewModel,
        ),
      ),
    );
  }
}

typedef DashboardScreen = DashboardView;
