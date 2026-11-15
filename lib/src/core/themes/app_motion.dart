import 'package:material_ui/material_ui.dart';

/// Design tokens and motion primitives following Emil Kowalski's animation philosophy.
///
/// Principles:
/// - Fast and purposeful (UI animations under 300ms).
/// - Transform & opacity only (GPU accelerated).
/// - Strong ease-out curve [cubic-bezier(0.23, 1, 0.32, 1)].
/// - Respects [MediaQueryData.disableAnimations] (prefers-reduced-motion).
class AppMotion {
  AppMotion._();

  /// Strong ease-out curve for UI entrances, transitions, and reactions.
  /// Equivalent to CSS cubic-bezier(0.23, 1, 0.32, 1).
  static const Curve easeOut = Cubic(0.23, 1.0, 0.32, 1.0);

  /// Strong ease-in-out curve for on-screen continuous or morphing movements.
  /// Equivalent to CSS cubic-bezier(0.77, 0, 0.175, 1).
  static const Curve easeInOut = Cubic(0.77, 0.0, 0.175, 1.0);

  /// Micro-interaction duration for touch / button presses (120ms).
  static const Duration durationPress = Duration(milliseconds: 120);

  /// Fast duration for hit punch and counter increments (180ms).
  static const Duration durationFast = Duration(milliseconds: 180);

  /// Standard duration for state transitions, badges, and progress glides (240ms).
  static const Duration durationStandard = Duration(milliseconds: 240);

  /// Calm breathing period for factory ambient notifications (1400ms).
  static const Duration durationBreathe = Duration(milliseconds: 1400);

  /// Helper to check whether reduced motion is requested by the OS or user.
  static bool isReducedMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }
}

/// A tactile button / card wrapper that scales down slightly (scale 0.96)
/// upon touch down and springs back smoothly upon release.
///
/// Uses [Listener] to guarantee zero interference with existing [onPressed] or [onTap] handlers.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Duration duration;
  final Curve curve;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
    this.duration = AppMotion.durationPress,
    this.curve = AppMotion.easeOut,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;

  void _onPointerDown(PointerDownEvent event) {
    if (!_isPressed) {
      setState(() => _isPressed = true);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReducedMotion(context);
    final targetScale = (reduced || !_isPressed) ? 1.0 : widget.pressedScale;

    Widget content = AnimatedScale(
      scale: targetScale,
      duration: widget.duration,
      curve: widget.curve,
      child: widget.child,
    );

    if (widget.onTap != null) {
      content = GestureDetector(onTap: widget.onTap, child: content);
    }

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: content,
    );
  }
}

/// A rolling numeric counter where each digit animates independently (odometer style).
///
/// For example, from 24 to 25: the '2' remains completely stationary, while only the '4'
/// slides up and exits to the top as '5' enters from the bottom.
///
/// Fully accessible (announces the complete number via [Semantics]) and strictly enforces
/// [FontFeature.tabularFigures()] with uniform digit widths to eliminate any horizontal jitter.
class SlidingCounterText extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const SlidingCounterText({
    super.key,
    required this.value,
    this.style,
    this.duration = AppMotion.durationFast,
    this.curve = AppMotion.easeOut,
  });

  @override
  State<SlidingCounterText> createState() => _SlidingCounterTextState();
}

class _SlidingCounterTextState extends State<SlidingCounterText> {
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant SlidingCounterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncrement = widget.value >= _previousValue;
    final reduced = AppMotion.isReducedMotion(context);

    final effectiveStyle = (widget.style ?? const TextStyle()).copyWith(
      fontFeatures: [
        ...?widget.style?.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );

    final textScaler =
        MediaQuery.maybeOf(context)?.textScaler ?? TextScaler.noScaling;
    final textPainter = TextPainter(
      text: TextSpan(text: '0', style: effectiveStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final digitWidth = textPainter.width;

    final isNegative = widget.value < 0;
    final str = widget.value.abs().toString();

    return Semantics(
      label: '${widget.value}',
      value: '${widget.value}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isNegative) Text('-', style: effectiveStyle),
          for (int i = 0; i < str.length; i++)
            _SingleDigitRoll(
              key: ValueKey<int>(str.length - 1 - i),
              char: str[i],
              digitWidth: digitWidth,
              style: effectiveStyle,
              duration: widget.duration,
              curve: widget.curve,
              isIncrement: isIncrement,
              reduced: reduced,
            ),
        ],
      ),
    );
  }
}

class _SingleDigitRoll extends StatelessWidget {
  final String char;
  final double digitWidth;
  final TextStyle style;
  final Duration duration;
  final Curve curve;
  final bool isIncrement;
  final bool reduced;

  const _SingleDigitRoll({
    super.key,
    required this.char,
    required this.digitWidth,
    required this.style,
    required this.duration,
    required this.curve,
    required this.isIncrement,
    required this.reduced,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: digitWidth,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x00FFFFFF),
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
              Color(0x00FFFFFF),
            ],
            stops: [0.0, 0.12, 0.88, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: duration,
            switchInCurve: curve,
            switchOutCurve: curve,
            layoutBuilder:
                (Widget? currentChild, List<Widget> previousChildren) {
              return Stack(
                alignment: Alignment.center,
                children: <Widget>[...previousChildren, ?currentChild],
              );
            },
            transitionBuilder: (Widget child, Animation<double> animation) {
              if (reduced) {
                return FadeTransition(opacity: animation, child: child);
              }

              final isIncoming =
                  (child.key as ValueKey<String>?)?.value == char;

              // True cash-register / odometer drum roll (Number ticker + Direction-aware):
              // Incrementing: outgoing rolls up (0.0 -> -1.0) while incoming rolls in right behind from bottom (1.0 -> 0.0).
              // Decrementing: outgoing rolls down (0.0 -> 1.0) while incoming rolls in from top (-1.0 -> 0.0).
              final offsetTween = isIncoming
                  ? Tween<Offset>(
                      begin: isIncrement
                          ? const Offset(0.0, 1.0)
                          : const Offset(0.0, -1.0),
                      end: Offset.zero,
                    )
                  : Tween<Offset>(
                      begin: isIncrement
                          ? const Offset(0.0, -1.0)
                          : const Offset(0.0, 1.0),
                      end: Offset.zero,
                    );

              return SlideTransition(
                position: offsetTween.animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Text(
              char,
              key: ValueKey<String>(char),
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// A smoothly interpolated linear progress bar that glides between progress values
/// using [TweenAnimationBuilder] and [AppMotion.easeOut].
class SmoothProgressBar extends StatelessWidget {
  final double value;
  final double minHeight;
  final Color progressColor;
  final Color backgroundColor;
  final BorderRadius borderRadius;
  final Duration duration;
  final Curve curve;

  const SmoothProgressBar({
    super.key,
    required this.value,
    this.minHeight = 6,
    required this.progressColor,
    required this.backgroundColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.duration = AppMotion.durationStandard,
    this.curve = AppMotion.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);
    final reduced = AppMotion.isReducedMotion(context);

    if (reduced) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: LinearProgressIndicator(
          value: clampedValue,
          minHeight: minHeight,
          backgroundColor: backgroundColor,
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: clampedValue),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, _) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: LinearProgressIndicator(
            value: animatedValue,
            minHeight: minHeight,
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        );
      },
    );
  }
}

/// A breathing luminescence wrapper for high-priority factory states
/// (e.g. "LOTE PRONTO! PODE RETIRAR" or "PORTA ABERTA").
///
/// Modulates opacity smoothly between [minOpacity] and 1.0 in a calm 1400ms cycle,
/// catching the operator's peripheral vision at a 4-meter distance without being jarring.
class BreathingGlow extends StatefulWidget {
  final Widget child;
  final bool isPulsing;
  final double minOpacity;
  final Duration duration;

  const BreathingGlow({
    super.key,
    required this.child,
    this.isPulsing = true,
    this.minOpacity = 0.78,
    this.duration = AppMotion.durationBreathe,
  });

  @override
  State<BreathingGlow> createState() => _BreathingGlowState();
}

class _BreathingGlowState extends State<BreathingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = Tween<double>(begin: widget.minOpacity, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BreathingGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReducedMotion(context);
    if (reduced || !widget.isPulsing) {
      return widget.child;
    }

    return FadeTransition(opacity: _animation, child: widget.child);
  }
}

/// Subtle value-change indicator that guides the operator's eye to whichever
/// metric just updated (e.g. Total Líquido, Caixas Fechadas, Quebras, or Temperature),
/// without running any continuous animation when idle.
///
/// Uses only GPU-friendly [ScaleTransition], [SlideTransition], and [FadeTransition]
/// with [AppMotion.easeOut] under 240ms, and respects reduced motion.
class AnimatedValueText extends StatefulWidget {
  final String value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final double pulseScale;

  const AnimatedValueText({
    super.key,
    required this.value,
    this.style,
    this.duration = AppMotion.durationFast,
    this.curve = AppMotion.easeOut,
    this.pulseScale = 1.05,
  });

  @override
  State<AnimatedValueText> createState() => _AnimatedValueTextState();
}

class _AnimatedValueTextState extends State<AnimatedValueText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  bool _isIncrement = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppMotion.durationStandard,
    );
    _configureScaleAnimation();
  }

  void _configureScaleAnimation() {
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: widget.pulseScale)
            .chain(CurveTween(curve: AppMotion.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: widget.pulseScale, end: 1.0)
            .chain(CurveTween(curve: AppMotion.easeOut)),
        weight: 60,
      ),
    ]).animate(_pulseController);
  }

  @override
  void didUpdateWidget(covariant AnimatedValueText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulseScale != widget.pulseScale) {
      _configureScaleAnimation();
    }
    if (oldWidget.value != widget.value) {
      final oldNum = double.tryParse(
        oldWidget.value.replaceAll(RegExp(r'[^0-9.-]'), ''),
      );
      final newNum = double.tryParse(
        widget.value.replaceAll(RegExp(r'[^0-9.-]'), ''),
      );
      if (oldNum != null && newNum != null) {
        _isIncrement = newNum >= oldNum;
      } else {
        _isIncrement = true;
      }
      _pulseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReducedMotion(context);

    final switcher = ClipRect(
      child: AnimatedSwitcher(
        duration: widget.duration,
        switchInCurve: widget.curve,
        switchOutCurve: widget.curve,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[...previousChildren, ?currentChild],
          );
        },
        transitionBuilder: (child, animation) {
          if (reduced) {
            return FadeTransition(opacity: animation, child: child);
          }

          final isIncoming =
              (child.key as ValueKey<String>?)?.value == widget.value;
          final offsetTween = isIncoming
              ? Tween<Offset>(
                  begin: _isIncrement
                      ? const Offset(0.0, 0.95)
                      : const Offset(0.0, -0.95),
                  end: Offset.zero,
                )
              : Tween<Offset>(
                  begin: _isIncrement
                      ? const Offset(0.0, -0.95)
                      : const Offset(0.0, 0.95),
                  end: Offset.zero,
                );

          return SlideTransition(
            position: offsetTween.animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Text(
          widget.value,
          key: ValueKey<String>(widget.value),
          style: widget.style,
        ),
      ),
    );

    if (reduced) {
      return switcher;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: switcher,
    );
  }
}
