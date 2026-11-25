import 'package:material_ui/material_ui.dart';

/// Standard Material 3 Responsive Breakpoints & Device Targets
/// Optimized for Factory Wall-mount Kiosk (e.g. Lenovo Idea Tab TB336FU 11" 2560x1600 16:10,
/// Samsung Galaxy A05 / SM-A055M) and Desktop Monitoring consoles.
abstract class AppBreakpoints {
  static const double compactMax = 600.0;
  static const double mediumMax = 840.0;
  static const double expandedMax = 1200.0;

  /// Lenovo Idea Tab TB336FU (11.0" 2560x1600 16:10 @ ~274 PPI -> ~1280x800 dp or 1067x667 dp)
  /// Minimum shortestSide (height in landscape) that distinguishes a 10"-11" 16:10 tablet from a phone kiosk (~360-412 dp).
  static const double tabletShortestSideMin = 540.0;
  static const double tabletLandscapeWidthMin = 900.0;

  /// Kiosk minimum touch target for factory floor operators with gloves: 48dp minimum (56dp on 11" Tablet)
  static const double minTouchTargetKiosk = 48.0;
  static const double minTouchTargetTablet = 56.0;

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

  /// True when running on a tablet kiosk like Lenovo Idea Tab TB336FU (11" 16:10, shortestSide >= 540dp).
  static bool isTabletKiosk(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.shortestSide >= tabletShortestSideMin &&
        size.longestSide >= tabletLandscapeWidthMin;
  }
}


