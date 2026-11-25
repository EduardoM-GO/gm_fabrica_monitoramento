import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_breakpoints.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/utils/time_formatter.dart';

/// Relógio operacional em tempo real para o modo Kiosk em tela cheia.
///
/// Isolado em seu próprio [StatefulWidget] para atualizar na virada exata
/// de cada minuto sem reconstruir a árvore principal e sem bloquear `pumpAndSettle`
/// em testes de widget.
final class KioskClockDisplay extends StatefulWidget {
  final DateTime Function()? nowProvider;

  const KioskClockDisplay({
    super.key,
    this.nowProvider,
  });

  @override
  State<KioskClockDisplay> createState() => _KioskClockDisplayState();
}

class _KioskClockDisplayState extends State<KioskClockDisplay>
    with WidgetsBindingObserver {
  Timer? _minuteTimer;
  late DateTime _currentTime;

  DateTime _now() => widget.nowProvider?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentTime = _now();
    _scheduleNextMinuteTick();
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onTick();
    }
  }

  void _scheduleNextMinuteTick() {
    _minuteTimer?.cancel();
    final now = _now();
    final msUntilNextMinute =
        ((60 - now.second) * 1000) - now.millisecond;
    final delay = Duration(
      milliseconds: msUntilNextMinute > 0 ? msUntilNextMinute : 1000,
    );
    _minuteTimer = Timer(delay, _onTick);
  }

  void _onTick() {
    if (!mounted) return;
    setState(() {
      _currentTime = _now();
    });
    _scheduleNextMinuteTick();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = AppBreakpoints.isTabletKiosk(context);
    final formatted = TimeFormatter.formatKioskClock(_currentTime);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: isTablet ? 16 : 12,
            color: AppTheme.textMuted.withValues(alpha: 0.85),
          ),
          SizedBox(width: isTablet ? 5 : 3),
          Text(
            formatted,
            key: const ValueKey('kiosk_clock_text'),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: isTablet ? 13.5 : 11,
              fontWeight: FontWeight.w700,
              fontFeatures: const [
                FontFeature.tabularFigures(),
              ],
              color: isTablet ? AppTheme.textSecondary : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
