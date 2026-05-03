import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/tempo/presentation/providers/stroke_rate_ramp_provider.dart';

void main() {
  group('StrokeRateRampNotifier', () {
    test('logs reps against generated stroke-rate targets', () {
      final notifier = StrokeRateRampNotifier();

      notifier.configure(
        startStrokeRate: 60,
        increment: 5,
        repeatDistanceMeters: 25,
        reps: 2,
        restDuration: const Duration(seconds: 20),
      );
      notifier.logRep(
        split: const Duration(seconds: 18),
        strokeCount: 18,
        rpe: 5,
        notes: 'smooth',
      );
      notifier.logRep(
        split: const Duration(seconds: 17),
        strokeCount: 20,
        rpe: 7,
      );
      notifier.logRep(
        split: const Duration(seconds: 16),
        strokeCount: 21,
      );

      expect(notifier.state.logs.map((log) => log.strokeRate), [60, 65]);
      expect(notifier.state.logs.first.distancePerStroke, closeTo(1.39, 0.01));
      expect(notifier.state.isComplete, isTrue);
      expect(notifier.state.lastStatus, 'Ramp complete.');
      expect(notifier.state.summary, contains('Fastest 1:08/100m'));
    });

    test('resets logs without changing the configured protocol', () {
      final notifier = StrokeRateRampNotifier();

      notifier.configure(
        startStrokeRate: 58,
        increment: 3,
        repeatDistanceMeters: 50,
        reps: 3,
        restDuration: const Duration(seconds: 30),
      );
      notifier.logRep(
        split: const Duration(seconds: 36),
        strokeCount: 35,
      );
      notifier.resetLogs();

      expect(notifier.state.logs, isEmpty);
      expect(notifier.state.currentTarget.strokeRate, 58);
      expect(notifier.state.repeatDistanceMeters, 50);
    });
  });
}
