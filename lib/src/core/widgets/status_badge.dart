import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';

/// Semáforo operacional M3: combina cor semântica + ícone/indicador + texto tabular.
/// Suporta o modo [subtle] para estados normais/em repouso que devem ficar mais tímidos na hierarquia.
final class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool showDot;
  final bool compact;
  final bool subtle;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.showDot = false,
    this.compact = false,
    this.subtle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = subtle ? color.withValues(alpha: 0.72) : color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : AppSpacing.xs,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: subtle ? 0.06 : 0.16),
        borderRadius: BorderRadius.circular(
          compact ? AppSpacing.radiusXs : AppSpacing.radiusSm,
        ),
        border: Border.all(
          color: color.withValues(alpha: subtle ? 0.20 : 0.50),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: compact ? 5 : 6,
              height: compact ? 5 : 6,
              decoration: BoxDecoration(
                color: effectiveColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: compact ? 4 : 6),
          ] else if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 10 : 13,
              color: effectiveColor,
            ),
            SizedBox(width: compact ? 3 : 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: compact ? 8.5 : 10.5,
                fontWeight: subtle ? FontWeight.w700 : FontWeight.w900,
                letterSpacing: subtle ? 0.2 : 0.4,
                color: effectiveColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

