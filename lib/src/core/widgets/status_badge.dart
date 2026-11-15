import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';

/// Semáforo operacional M3: combina cor semântica + ícone/indicador + texto tabular.
final class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool showDot;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.showDot = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : AppSpacing.xs,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(
          compact ? AppSpacing.radiusXs : AppSpacing.radiusSm,
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.48),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: compact ? 6 : 7,
              height: compact ? 6 : 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: compact ? 4 : 6),
          ] else if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 11 : 14,
              color: color,
            ),
            SizedBox(width: compact ? 4 : 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: compact ? 8.5 : 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

