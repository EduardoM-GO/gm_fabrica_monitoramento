class TimeFormatter {
  TimeFormatter._();

  /// Formats uptime from milliseconds to `Xh Ym Zs` or `Ym Zs`
  static String formatUptime(int uptimeMs) {
    if (uptimeMs <= 0) return '0s';
    final totalSeconds = (uptimeMs / 1000).floor();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Formats a Duration into `MM:SS` or `Xh Ym Zs`
  static String formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00';
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Formats temperature delta with + or - sign, e.g. "+2.3 °C" or "-1.5 °C"
  static String formatTemperatureDelta(double delta) {
    final sign = delta > 0 ? '+' : '';
    return '$sign${delta.toStringAsFixed(1)} °C';
  }
}

