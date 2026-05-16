import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/tempo/domain/services/css_pace_calculator.dart';
import 'package:rep_swim/features/tempo/domain/services/stroke_rate_ramp_calculator.dart';
import 'package:rep_swim/features/tempo/domain/services/tempo_calculator.dart';
import 'package:rep_swim/features/tempo/domain/services/usrpt_calculator.dart';

void main() {
  group('TempoCalculator', () {
    const calculator = TempoCalculator();

    test('converts stroke rate to beat interval and back', () {
      final interval = calculator.beatIntervalForStrokeRate(60);

      expect(interval, const Duration(seconds: 1));
      expect(calculator.strokeRateForBeatInterval(interval), 60);
    });

    test('calculates split and pace targets', () {
      const targetTime = Duration(seconds: 88);

      expect(
        calculator.splitForDistance(
          targetTime: targetTime,
          targetDistanceMeters: 100,
          splitDistanceMeters: 25,
        ),
        const Duration(seconds: 22),
      );
      expect(
        calculator.pacePer100(
          targetTime: const Duration(minutes: 5, seconds: 40),
          targetDistanceMeters: 400,
        ),
        const Duration(seconds: 85),
      );
    });

    test('compares actual splits against a target', () {
      final results = calculator.compareSplits(
        actualSplits: const [
          Duration(milliseconds: 22500),
          Duration(milliseconds: 23200),
        ],
        targetSplit: const Duration(seconds: 23),
        strokeCounts: const [18, 20],
      );

      expect(results.first.error, const Duration(milliseconds: -500));
      expect(results.first.isOnPace, isTrue);
      expect(results.last.strokeCount, 20);
      expect(
        calculator.averageSplitError(results),
        const Duration(milliseconds: -150),
      );
    });

    test('flags high breath intervals for safety acknowledgement', () {
      expect(calculator.requiresBreathSafetyWarning(4), isFalse);
      expect(calculator.requiresBreathSafetyWarning(5), isTrue);
    });
  });

  group('StrokeRateRampCalculator', () {
    const calculator = StrokeRateRampCalculator();

    test('generates stroke-rate targets per repetition', () {
      final protocol = calculator.generate(
        startStrokeRate: 60,
        increment: 4,
        repeatDistanceMeters: 25,
        reps: 4,
        restDuration: const Duration(seconds: 20),
      );

      expect(protocol.targets.map((target) => target.strokeRate), [
        60,
        64,
        68,
        72,
      ]);
      expect(protocol.targets.last.repeatDistanceMeters, 25);
      expect(protocol.targets.last.restDuration, const Duration(seconds: 20));
    });

    test('rejects impossible ramp protocol values', () {
      expect(
        () => calculator.generate(
          startStrokeRate: 0,
          increment: 4,
          repeatDistanceMeters: 25,
          reps: 4,
          restDuration: const Duration(seconds: 20),
        ),
        throwsArgumentError,
      );
      expect(
        () => calculator.generate(
          startStrokeRate: 60,
          increment: -1,
          repeatDistanceMeters: 25,
          reps: 4,
          restDuration: const Duration(seconds: 20),
        ),
        throwsArgumentError,
      );
    });
  });

  group('UsrptRacePaceCalculator', () {
    const calculator = UsrptRacePaceCalculator();

    test('calculates race pace split targets for repetitions', () {
      final preset = calculator.calculate(
        eventDistanceMeters: 100,
        eventTargetTime: const Duration(seconds: 60),
        repetitionDistanceMeters: 25,
        restDuration: const Duration(seconds: 20),
        failLimit: 3,
      );

      expect(preset.repetitionTargetTime, const Duration(seconds: 15));
      expect(preset.restDuration, const Duration(seconds: 20));
      expect(preset.repetitionsPerRace, 4);
    });

    test('rejects impossible race pace inputs', () {
      expect(
        () => calculator.calculate(
          eventDistanceMeters: 100,
          eventTargetTime: Duration.zero,
          repetitionDistanceMeters: 25,
          restDuration: const Duration(seconds: 20),
          failLimit: 3,
        ),
        throwsArgumentError,
      );
      expect(
        () => calculator.calculate(
          eventDistanceMeters: 50,
          eventTargetTime: const Duration(seconds: 30),
          repetitionDistanceMeters: 100,
          restDuration: const Duration(seconds: 20),
          failLimit: 3,
        ),
        throwsArgumentError,
      );
    });
  });

  group('CssPaceCalculator', () {
    const calculator = CssPaceCalculator();

    test('calculates CSS pace and pool split targets', () {
      final preset = calculator.calculate(
        time200: const Duration(minutes: 2, seconds: 30),
        time400: const Duration(minutes: 5, seconds: 20),
      );

      expect(preset.pacePer100, const Duration(seconds: 85));
      expect(preset.split25, const Duration(milliseconds: 21250));
      expect(preset.split50, const Duration(milliseconds: 42500));
      expect(preset.cssMetersPerSecond, closeTo(1.176, 0.001));
    });

    test('rejects missing or impossible CSS times', () {
      expect(
        () => calculator.calculate(
          time200: Duration.zero,
          time400: const Duration(minutes: 5),
        ),
        throwsArgumentError,
      );
      expect(
        () => calculator.calculate(
          time200: const Duration(minutes: 5),
          time400: const Duration(minutes: 4),
        ),
        throwsArgumentError,
      );
      expect(
        () => calculator.calculate(
          time200: const Duration(minutes: 2, seconds: 30),
          time400: const Duration(minutes: 4, seconds: 40),
        ),
        throwsArgumentError,
      );
    });
  });
}
