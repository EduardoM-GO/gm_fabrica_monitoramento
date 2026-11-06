import 'package:flutter/material.dart';

/// Standard Material 3 Responsive Breakpoints & Device Targets
/// Optimized for Factory Wall-mount Kiosk (e.g. Samsung Galaxy A05 / SM-A055M)
/// and Desktop Monitoring consoles.
abstract class AppBreakpoints {
  static const double compactMax = 600.0;
  static const double mediumMax = 840.0;
  static const double expandedMax = 1200.0;

  /// Kiosk minimum touch target for factory floor operators with gloves: 48dp minimum
  static const double minTouchTargetKiosk = 48.0;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactMax;

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= compactMax && width < mediumMax;
  }

  static bool isExpanded(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mediumMax && width < expandedMax;
  }

  static bool isLarge(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expandedMax;

  static bool isLandscape(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width > size.height;
  }
}

