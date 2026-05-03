class CssPacePreset {
  const CssPacePreset({
    required this.cssMetersPerSecond,
    required this.pacePer100,
    required this.split25,
    required this.split50,
  });

  final double cssMetersPerSecond;
  final Duration pacePer100;
  final Duration split25;
  final Duration split50;
}

class CssPaceCalculator {
  const CssPaceCalculator();

  CssPacePreset calculate({
    required Duration time200,
    required Duration time400,
  }) {
    if (time200 <= Duration.zero || time400 <= Duration.zero) {
      throw ArgumentError('CSS times must be positive.');
    }
    if (time400 <= time200) {
      throw ArgumentError('400m time must be slower than 200m time.');
    }
    if (time400 <= time200 * 2) {
      throw ArgumentError('400m pace must be slower than 200m pace.');
    }

    final deltaMicroseconds = time400.inMicroseconds - time200.inMicroseconds;
    final cssMetersPerSecond =
        200 * Duration.microsecondsPerSecond / deltaMicroseconds;
    final pacePer100 = Duration(microseconds: (deltaMicroseconds / 2).round());

    return CssPacePreset(
      cssMetersPerSecond: cssMetersPerSecond,
      pacePer100: pacePer100,
      split25: Duration(microseconds: (pacePer100.inMicroseconds / 4).round()),
      split50: Duration(microseconds: (pacePer100.inMicroseconds / 2).round()),
    );
  }
}
