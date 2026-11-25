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

  static const List<String> _ptBrWeekdays = [
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];

  /// Formats current date and time in pt-BR short format: `Ter, 24/11 • 14:35`
  static String formatKioskClock(DateTime dateTime) {
    final weekday = _ptBrWeekdays[(dateTime.weekday - 1).clamp(0, 6)];
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$weekday, $day/$month • $hour:$minute';
  }
}
