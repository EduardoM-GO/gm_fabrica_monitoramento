sealed class IncomingFrame {
  const IncomingFrame();

  factory IncomingFrame.fromJson(Map<String, dynamic> json) {
    final type = json['t'] as String?;
    if (type == 'hit') {
      return HitFrame.fromJson(json);
    } else if (type == 'telem') {
      return TelemetryFrame.fromJson(json);
    }
    throw FormatException('Unknown frame type: $type');
  }
}

class FreezerRawData {
  final double temp;
  final int door;
  final int ok;

  const FreezerRawData({
    required this.temp,
    required this.door,
    required this.ok,
  });

  bool get isDoorOpen => door == 1;
  bool get isProbeOk => ok == 1;

  static FreezerRawData? fromJson(dynamic json) {
    if (json == null || json is! Map<String, dynamic>) {
      return null;
    }
    if (!json.containsKey('temp') && !json.containsKey('d') && !json.containsKey('ok')) {
      return null;
    }
    return FreezerRawData(
      temp: (json['temp'] as num?)?.toDouble() ?? 0.0,
      door: (json['d'] as num?)?.toInt() ?? 0,
      ok: (json['ok'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'temp': temp,
    'd': door,
    'ok': ok,
  };
}

class TelemetryFrame extends IncomingFrame {
  final int uptimeMs;
  final int eggCount;
  final FreezerRawData? freezer1;
  final FreezerRawData? freezer2;

  const TelemetryFrame({
    required this.uptimeMs,
    required this.eggCount,
    this.freezer1,
    this.freezer2,
  });

  factory TelemetryFrame.fromJson(Map<String, dynamic> json) {
    return TelemetryFrame(
      uptimeMs: (json['up'] as num?)?.toInt() ?? 0,
      eggCount: (json['c'] as num?)?.toInt() ?? 0,
      freezer1: FreezerRawData.fromJson(json['f1']),
      freezer2: FreezerRawData.fromJson(json['f2']),
    );
  }

  Map<String, dynamic> toJson() => {
    't': 'telem',
    'up': uptimeMs,
    'c': eggCount,
    if (freezer1 != null) 'f1': freezer1!.toJson(),
    if (freezer2 != null) 'f2': freezer2!.toJson(),
  };
}

class HitFrame extends IncomingFrame {
  final int eggCount;

  const HitFrame({required this.eggCount});

  factory HitFrame.fromJson(Map<String, dynamic> json) {
    return HitFrame(
      eggCount: (json['c'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    't': 'hit',
    'c': eggCount,
  };
}
