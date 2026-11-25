import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_breakpoints.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/status_badge.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/ui/view_models/freezer_monitoring_view_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/ui/view_models/egg_count_view_model.dart';
import 'package:signals/signals_flutter.dart';

/// Cabeçalho compacto full-screen para as telas operacionais do Kiosk.
/// Exibe botão Voltar amplo, título da tela, alertas ao vivo (Alarme Térmico de Porta
/// ou Esteira sem Lote) e ações primárias à direita.
/// Otimizado tanto para Kiosk compacto quanto para Tablet 11" Lenovo Idea Tab TB336FU.
final class KioskSubpageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final EggCountViewModel? eggViewModel;
  final FreezerMonitoringViewModel? freezerViewModel;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final String backLabel;

  const KioskSubpageHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.eggViewModel,
    this.freezerViewModel,
    this.actions = const [],
    this.onBack,
    this.backLabel = 'Fechar',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = AppBreakpoints.isTabletKiosk(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? AppSpacing.md : AppSpacing.sm,
        vertical: isTablet ? 10 : 6,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          // Botão Voltar / Fechar com área de toque ampla para chão de fábrica
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              visualDensity:
                  isTablet ? VisualDensity.standard : VisualDensity.compact,
              minimumSize: Size(0, isTablet ? 44 : 36),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 12,
                vertical: isTablet ? 10 : 6,
              ),
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.onSurface,
            ),
            onPressed: onBack ?? () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_rounded, size: isTablet ? 18 : 16),
            label: Text(
              backLabel,
              style: TextStyle(
                fontSize: isTablet ? 13.5 : 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: isTablet ? AppSpacing.md : AppSpacing.sm),

          // Ícone + Título + Subtítulo
          Container(
            padding: EdgeInsets.all(isTablet ? 8 : 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: AppSpacing.borderRadiusXs,
            ),
            child: Icon(
              icon,
              size: isTablet ? 20 : 16,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          SizedBox(width: isTablet ? AppSpacing.sm : AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFamily: AppTheme.fontHeading,
                    fontWeight: FontWeight.w900,
                    fontSize: isTablet ? 16 : 13.5,
                    letterSpacing: 0.4,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: isTablet ? 12 : 10.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),

          // Alertas ao vivo da fábrica enquanto o operador está na tela secundária
          if (freezerViewModel != null)
            SignalBuilder(
              builder: (context) {
                final hasAlarm = freezerViewModel!.hasDoorAlarm.value;
                if (!hasAlarm) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.xs),
                  child: StatusBadge(
                    label: 'ALARME PORTA ABERTA',
                    color: AppTheme.dangerRed,
                    icon: Icons.warning_amber_rounded,
                    compact: true,
                  ),
                );
              },
            ),

          if (eggViewModel != null)
            SignalBuilder(
              builder: (context) {
                final conveyorAlert =
                    eggViewModel!.isConveyorRunningWithoutBatch.value;
                if (!conveyorAlert) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.xs),
                  child: StatusBadge(
                    label: 'ESTEIRA SEM LOTE',
                    color: AppTheme.warningAmber,
                    icon: Icons.conveyor_belt,
                    compact: true,
                  ),
                );
              },
            ),

          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) SizedBox(width: isTablet ? AppSpacing.sm : AppSpacing.xs),
            actions[i],
          ],
        ],
      ),
    );
  }
}
