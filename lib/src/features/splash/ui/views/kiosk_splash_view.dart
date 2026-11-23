import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_motion.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_spacing.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/status_badge.dart';

/// Tela de Splash Kiosk Industrial (Material Design 3 Dark - Cacau & Ouro Nobre)
/// otimizada para chão de fábrica horizontal (~800x360 dp).
/// Exibe a identidade visual G&M Chocolates, o emblema de telemetria (Produção + Refrigeração)
/// e realiza transição suave para o painel principal.
final class KioskSplashView extends StatefulWidget {
  final Widget nextChild;
  final Duration duration;

  const KioskSplashView({
    super.key,
    required this.nextChild,
    this.duration = const Duration(milliseconds: 1800),
  });

  @override
  State<KioskSplashView> createState() => _KioskSplashViewState();
}

class _KioskSplashViewState extends State<KioskSplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _completionTimer;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.easeOut),
    );

    _controller.forward();

    if (widget.duration <= Duration.zero) {
      _isCompleted = true;
    } else {
      _completionTimer = Timer(widget.duration, () {
        if (mounted) {
          setState(() => _isCompleted = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _skipSplash() {
    _completionTimer?.cancel();
    if (!_isCompleted && mounted) {
      setState(() => _isCompleted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.durationStandard,
      switchInCurve: AppMotion.easeOut,
      switchOutCurve: AppMotion.easeOut,
      child: _isCompleted
          ? KeyedSubtree(
              key: const ValueKey('kiosk_splash_next_child'),
              child: widget.nextChild,
            )
          : KeyedSubtree(
              key: const ValueKey('kiosk_splash_active'),
              child: _buildSplashContent(context),
            ),
    );
  }

  Widget _buildSplashContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skipSplash,
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.95,
              colors: [
                AppTheme.surfaceElevated,
                AppTheme.background,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Card.outlined(
                        color: colorScheme.surfaceContainer.withValues(
                          alpha: 0.92,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.borderRadiusXl,
                          side: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.35),
                            width: 1.4,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Emblema Oficial G&M Chocolates (com fallback vetorial seguro)
                                  Container(
                                    width: 104,
                                    height: 104,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerLowest,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Image.asset(
                                      'assets/branding/splash_logo.png',
                                      key: const ValueKey('kiosk_splash_logo'),
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => Icon(
                                        Icons.factory_rounded,
                                        size: 48,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            StatusBadge(
                                              label: 'KIOSK INDUSTRIAL M3',
                                              color: colorScheme.primary,
                                              icon: Icons.precision_manufacturing_rounded,
                                              compact: true,
                                            ),
                                            const SizedBox(width: 6),
                                            StatusBadge(
                                              label: 'TELEMETRIA 0ms',
                                              color: colorScheme.tertiary,
                                              icon: Icons.ac_unit_rounded,
                                              compact: true,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'G&M CHOCOLATES FINOS',
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                fontFamily:
                                                    AppTheme.fontHeading,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.8,
                                                color: colorScheme.primary,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Monitoramento de Esteira, Embalagem & Cristalização Adaptativa',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ClipRRect(
                                borderRadius: AppSpacing.borderRadiusXs,
                                child: LinearProgressIndicator(
                                  minHeight: 5,
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.sensors_rounded,
                                          size: 14,
                                          color: colorScheme.tertiary,
                                        ),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            'Inicializando sensores ESP32, SQLite Drift & Catálogo Supabase...',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: AppTheme.textMuted,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Toque para entrar →',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
