import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_breakpoints.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
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
/// Segue estritamente Material Design 3 e alta densidade visual.
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

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopKioskStatusStrip(
                    eggViewModel: eggViewModel,
                    freezerViewModel: freezerViewModel,
                    settingsViewModel: settingsViewModel,
                  ),
                  const SizedBox(height: 8),
                  if (isLandscape && isWideEnough)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Zona Esquerda (60%): Embalagem e Contagem de Ovos (0ms)
                        Expanded(
                          flex: 6,
                          child: EggCountCard(viewModel: eggViewModel),
                        ),
                        const SizedBox(width: 10),
                        // Zona Direita (40%): Monitoramento Adaptativo dos 2 Freezers
                        Expanded(
                          flex: 4,
                          child: FreezerMonitoringZone(
                            viewModel: freezerViewModel,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EggCountCard(viewModel: eggViewModel),
                        const SizedBox(height: 10),
                        FreezerMonitoringZone(viewModel: freezerViewModel),
                      ],
                    ),
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

        return Row(
          children: [
            // Identificação da Linha de Produção
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.factory_rounded,
                      size: 15,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'G&M CHOCOLATES',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Pill de Ambiente da Sala 4x4m
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thermostat_rounded,
                        size: 15,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        room != null
                            ? 'Sala: ${room.temp.toStringAsFixed(1)} °C • ${room.humidity.toStringAsFixed(0)}% UR'
                            : 'Sala: --.- °C • --% UR',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Pill de Status WebSocket + Botão de Configurações
            Flexible(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _openSettings(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.settings_rounded,
                          size: 15,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
