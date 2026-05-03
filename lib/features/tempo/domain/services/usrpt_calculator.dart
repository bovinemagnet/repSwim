class UsrptRacePacePreset {
  const UsrptRacePacePreset({
    required this.eventDistanceMeters,
    required this.eventTargetTime,
    required this.repetitionDistanceMeters,
    required this.repetitionTargetTime,
    required this.restDuration,
    required this.failLimit,
  });

  final int eventDistanceMeters;
  final Duration eventTargetTime;
  final int repetitionDistanceMeters;
  final Duration repetitionTargetTime;
  final Duration restDuration;
  final int failLimit;

  double get repetitionsPerRace =>
      eventDistanceMeters / repetitionDistanceMeters;
}

class UsrptRepOutcome {
  const UsrptRepOutcome({
    required this.index,
    required this.passed,
  });

  final int index;
  final bool passed;

  String get label => passed ? 'P' : 'F';
}

class UsrptRacePaceCalculator {
  const UsrptRacePaceCalculator();

  UsrptRacePacePreset calculate({
    required int eventDistanceMeters,
    required Duration eventTargetTime,
    required int repetitionDistanceMeters,
    required Duration restDuration,
    required int failLimit,
  }) {
    if (eventDistanceMeters <= 0 ||
        repetitionDistanceMeters <= 0 ||
        eventTargetTime <= Duration.zero ||
        restDuration < Duration.zero ||
        failLimit <= 0) {
      throw ArgumentError('USRPT values must be positive.');
    }
    if (repetitionDistanceMeters > eventDistanceMeters) {
      throw ArgumentError('Repeat distance cannot exceed event distance.');
    }

    final ratio = repetitionDistanceMeters / eventDistanceMeters;
    return UsrptRacePacePreset(
      eventDistanceMeters: eventDistanceMeters,
      eventTargetTime: eventTargetTime,
      repetitionDistanceMeters: repetitionDistanceMeters,
      repetitionTargetTime: Duration(
        microseconds: (eventTargetTime.inMicroseconds * ratio).round(),
      ),
      restDuration: restDuration,
      failLimit: failLimit,
    );
  }
}
