class StrokeRateRampRep {
  const StrokeRateRampRep({
    required this.index,
    required this.strokeRate,
    required this.repeatDistanceMeters,
    required this.restDuration,
  });

  final int index;
  final double strokeRate;
  final int repeatDistanceMeters;
  final Duration restDuration;
}

class StrokeRateRampProtocol {
  const StrokeRateRampProtocol({
    required this.startStrokeRate,
    required this.increment,
    required this.repeatDistanceMeters,
    required this.reps,
    required this.restDuration,
    required this.targets,
  });

  final double startStrokeRate;
  final double increment;
  final int repeatDistanceMeters;
  final int reps;
  final Duration restDuration;
  final List<StrokeRateRampRep> targets;
}

class StrokeRateRampRepLog {
  const StrokeRateRampRepLog({
    required this.index,
    required this.strokeRate,
    required this.repeatDistanceMeters,
    required this.split,
    required this.strokeCount,
    this.rpe,
    this.notes,
  });

  final int index;
  final double strokeRate;
  final int repeatDistanceMeters;
  final Duration split;
  final int strokeCount;
  final int? rpe;
  final String? notes;

  Duration get pacePer100 => Duration(
        milliseconds:
            (split.inMilliseconds * 100 / repeatDistanceMeters).round(),
      );

  double get distancePerStroke => repeatDistanceMeters / strokeCount;
}

class StrokeRateRampCalculator {
  const StrokeRateRampCalculator();

  StrokeRateRampProtocol generate({
    required double startStrokeRate,
    required double increment,
    required int repeatDistanceMeters,
    required int reps,
    required Duration restDuration,
  }) {
    if (startStrokeRate <= 0 ||
        increment < 0 ||
        repeatDistanceMeters <= 0 ||
        reps <= 0 ||
        restDuration < Duration.zero) {
      throw ArgumentError('Ramp values must be positive.');
    }

    return StrokeRateRampProtocol(
      startStrokeRate: startStrokeRate,
      increment: increment,
      repeatDistanceMeters: repeatDistanceMeters,
      reps: reps,
      restDuration: restDuration,
      targets: [
        for (var i = 0; i < reps; i += 1)
          StrokeRateRampRep(
            index: i + 1,
            strokeRate: startStrokeRate + increment * i,
            repeatDistanceMeters: repeatDistanceMeters,
            restDuration: restDuration,
          ),
      ],
    );
  }
}
