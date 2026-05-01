import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/stopwatch/presentation/providers/interval_timer_provider.dart';

void main() {
  group('IntervalTimerNotifier', () {
    test('advances through swim, rest, and complete phases', () {
      fakeAsync((async) {
        final notifier = IntervalTimerNotifier()
          ..configure(
            sets: 1,
            reps: 2,
            workDuration: const Duration(seconds: 2),
            restDuration: const Duration(seconds: 1),
          )
          ..start();

        expect(notifier.state.phase, IntervalPhase.swim);
        expect(notifier.state.remaining, const Duration(seconds: 2));

        async.elapse(const Duration(seconds: 2));
        expect(notifier.state.phase, IntervalPhase.rest);
        expect(notifier.state.remaining, const Duration(seconds: 1));

        async.elapse(const Duration(seconds: 1));
        expect(notifier.state.phase, IntervalPhase.swim);
        expect(notifier.state.currentRep, 2);

        async.elapse(const Duration(seconds: 2));
        expect(notifier.state.phase, IntervalPhase.complete);
        expect(notifier.state.isRunning, isFalse);

        notifier.dispose();
      });
    });

    test('reset preserves configuration', () {
      final notifier = IntervalTimerNotifier()
        ..configure(
          sets: 2,
          reps: 3,
          workDuration: const Duration(seconds: 20),
          restDuration: const Duration(seconds: 5),
        )
        ..skipPhase()
        ..reset();

      expect(notifier.state.sets, 2);
      expect(notifier.state.reps, 3);
      expect(notifier.state.remaining, const Duration(seconds: 20));
      expect(notifier.state.phase, IntervalPhase.ready);

      notifier.dispose();
    });
  });
}
