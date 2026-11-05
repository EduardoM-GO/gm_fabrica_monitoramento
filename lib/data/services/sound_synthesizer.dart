import 'dart:math' as math;
import 'dart:typed_data';

/// High-efficiency, zero-asset acoustic synthesizer for factory floor indicative sounds.
///
/// Implements industrial earcons (auditory icons):
/// - Optical POS barcode scanner beep (2600 Hz, 48ms) for instantaneous egg registration.
/// - Low cancel tone for manual decrement / undo (-1 egg).
/// - Dual affirmative chirp ("bip-BIP!") for box completion (40/50 eggs).
/// - Triple ascending machine chime for freezer demold readiness (audible across 4m).
/// - Intermittent ISO warning pulses for open freezer doors.
class SoundSynthesizer {
  SoundSynthesizer._();

  static const int sampleRate = 44100;

  /// The authentic supermarket POS scanner "good read" beep (2600 Hz, 48ms).
  ///
  /// Standardized industrial scanner signature (Honeywell / Zebra POS):
  /// - Operating frequency: 2600 Hz (peak sensitivity of human Fletcher-Munson curve).
  /// - Ultra-short duration: 48ms with 2ms attack and 5ms release to avoid DC clicks.
  /// - Allows the packaging operator to know with 100% certainty that the egg registered
  ///   without ever needing to look at the screen.
  static Uint8List createEggHitWav() {
    return _generateWav(
      durationMs: 48,
      sampleGenerator: (t, total) {
        double envelope;
        if (t < 0.002) {
          envelope = t / 0.002; // 2ms quick attack
        } else if (t > total - 0.005) {
          envelope = (total - t) / 0.005; // 5ms smooth release
        } else {
          envelope = 1.0;
        }

        // Clean scanner frequency (2600 Hz) with 8% second harmonic (5200 Hz) for crispness
        final fundamental = math.sin(2.0 * math.pi * 2600.0 * t);
        final secondHarmonic = math.sin(2.0 * math.pi * 5200.0 * t) * 0.08;

        return (fundamental + secondHarmonic) * envelope * 0.85;
      },
    );
  }

  /// Low cancel/correction tone (480 Hz -> 320 Hz, 85ms) for egg subtraction (-1).
  /// Unmistakably conveys "item removed / correction" through a low-frequency descending ramp.
  static Uint8List createEggUndoWav() {
    return _generateWav(
      durationMs: 85,
      sampleGenerator: (t, total) {
        final progress = t / total;
        final freq = 480.0 - (160.0 * progress);
        final envelope = math.sin(math.pi * progress);
        final osc = math.sin(2.0 * math.pi * freq * t);
        return osc * envelope * 0.75;
      },
    );
  }

  /// Dual affirmative chirp ("bip-BIP!") indicating full box (40 or 50 eggs).
  ///
  /// Universal checkout / packing completion earcon:
  /// - Beep 1: 2200 Hz (35ms)
  /// - Silence: 25ms
  /// - Beep 2: 3100 Hz (65ms)
  /// Instantly alerts the operator to tape the box and move the next box in place.
  static Uint8List createBoxCompletedWav() {
    return _generateWav(
      durationMs: 140,
      sampleGenerator: (t, total) {
        if (t < 0.035) {
          final env = math.sin(math.pi * (t / 0.035));
          return math.sin(2.0 * math.pi * 2200.0 * t) * env * 0.85;
        } else if (t >= 0.060 && t < 0.130) {
          final subT = t - 0.060;
          final env = math.sin(math.pi * (subT / 0.070));
          return math.sin(2.0 * math.pi * 3100.0 * subT) * env * 0.90;
        }
        return 0.0;
      },
    );
  }

  /// Triple ascending chime (1200 -> 1500 -> 1800 Hz, 360ms) for ready batch demolding.
  /// Clearly distinguishable across 4 meters of ambient noise in a chocolate tempering room.
  static Uint8List createFreezerReadyWav() {
    return _generateWav(
      durationMs: 360,
      sampleGenerator: (t, total) {
        if (t < 0.08) {
          final env = math.sin(math.pi * (t / 0.08));
          return math.sin(2.0 * math.pi * 1200.0 * t) * env * 0.80;
        } else if (t >= 0.10 && t < 0.18) {
          final subT = t - 0.10;
          final env = math.sin(math.pi * (subT / 0.08));
          return math.sin(2.0 * math.pi * 1500.0 * subT) * env * 0.85;
        } else if (t >= 0.20 && t < 0.32) {
          final subT = t - 0.20;
          final env = math.sin(math.pi * (subT / 0.12));
          return math.sin(2.0 * math.pi * 1800.0 * subT) * env * 0.90;
        }
        return 0.0;
      },
    );
  }

  /// Two-tone industrial warning buzzer for open freezer doors (1600 Hz, 240ms).
  /// High urgency without ear-splitting shrillness.
  static Uint8List createDoorAlarmWav() {
    return _generateWav(
      durationMs: 250,
      sampleGenerator: (t, total) {
        if (t < 0.09) {
          final env = math.sin(math.pi * (t / 0.09));
          return math.sin(2.0 * math.pi * 1600.0 * t) * env * 0.90;
        } else if (t >= 0.13 && t < 0.22) {
          final subT = t - 0.13;
          final env = math.sin(math.pi * (subT / 0.09));
          return math.sin(2.0 * math.pi * 1600.0 * subT) * env * 0.90;
        }
        return 0.0;
      },
    );
  }

  /// Generates a valid RIFF/WAVE header and 16-bit signed PCM data.
  static Uint8List _generateWav({
    required int durationMs,
    required double Function(double t, double totalSeconds) sampleGenerator,
  }) {
    final totalSeconds = durationMs / 1000.0;
    final totalSamples = (sampleRate * totalSeconds).toInt();
    final dataSize = totalSamples * 2; // 16-bit mono = 2 bytes per sample
    final fileSize = 36 + dataSize;

    final buffer = Uint8List(44 + dataSize);
    final view = ByteData.view(buffer.buffer);

    // 1. RIFF Chunk Descriptor
    _writeAscii(buffer, 0, 'RIFF');
    view.setUint32(4, fileSize, Endian.little);
    _writeAscii(buffer, 8, 'WAVE');

    // 2. "fmt " Sub-chunk
    _writeAscii(buffer, 12, 'fmt ');
    view.setUint32(16, 16, Endian.little); // Subchunk1Size = 16 for PCM
    view.setUint16(20, 1, Endian.little); // AudioFormat = 1 (PCM)
    view.setUint16(22, 1, Endian.little); // NumChannels = 1 (Mono)
    view.setUint32(24, sampleRate, Endian.little); // SampleRate = 44100
    view.setUint32(28, sampleRate * 2, Endian.little); // ByteRate = SampleRate * 1 * 2
    view.setUint16(32, 2, Endian.little); // BlockAlign = 1 * 2 = 2
    view.setUint16(34, 16, Endian.little); // BitsPerSample = 16

    // 3. "data" Sub-chunk
    _writeAscii(buffer, 36, 'data');
    view.setUint32(40, dataSize, Endian.little);

    // 4. Sample Data
    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final rawSample = sampleGenerator(t, totalSeconds);
      final clamped = rawSample.clamp(-1.0, 1.0);
      final intSample = (clamped * 32767.0).round();
      view.setInt16(44 + (i * 2), intSample, Endian.little);
    }

    return buffer;
  }

  static void _writeAscii(Uint8List buffer, int offset, String text) {
    for (int i = 0; i < text.length; i++) {
      buffer[offset + i] = text.codeUnitAt(i);
    }
  }
}
