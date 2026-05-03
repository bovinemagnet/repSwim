import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/tempo/presentation/providers/tempo_cue_scheduler.dart';

class _FakeTempoClock implements TempoClock {
  @override
  Duration elapsed = Duration.zero;
  bool started = false;

  @override
  void start() => started = true;

  @override
  void stop() => started = false;

  @override
  void reset() => elapsed = Duration.zero;
}

class _ManualTimer implements Timer {
  bool _isActive = true;

  @override
  bool get isActive => _isActive;

  @override
  int get tick => 0;

  @override
  void cancel() => _isActive = false;
}

void main() {
  group('TempoCueScheduler', () {
    test('schedules cues against absolute elapsed time to avoid drift', () {
      final clock = _FakeTempoClock();
      final delays = <Duration>[];
      final callbacks = <void Function()>[];
      var cueCount = 0;

      final scheduler = TempoCueScheduler(
        clockFactory: () => clock,
        timerFactory: (duration, callback) {
          delays.add(duration);
          callbacks.add(callback);
          return _ManualTimer();
        },
      );

      scheduler.start(
        interval: const Duration(seconds: 1),
        onCue: () => cueCount += 1,
      );

      expect(delays.single, const Duration(seconds: 1));

      clock.elapsed = const Duration(milliseconds: 1050);
      callbacks.removeAt(0)();

      expect(cueCount, 1);
      expect(delays.last, const Duration(milliseconds: 950));

      clock.elapsed = const Duration(milliseconds: 2120);
      callbacks.removeAt(0)();

      expect(cueCount, 2);
      expect(delays.last, const Duration(milliseconds: 880));

      scheduler.stop();
      expect(clock.started, isFalse);
    });

    test('does not accumulate callback delay across long sessions', () {
      final clock = _FakeTempoClock();
      final delays = <Duration>[];
      final callbacks = <void Function()>[];
      var cueCount = 0;

      final scheduler = TempoCueScheduler(
        clockFactory: () => clock,
        timerFactory: (duration, callback) {
          delays.add(duration);
          callbacks.add(callback);
          return _ManualTimer();
        },
      );

      scheduler.start(
        interval: const Duration(seconds: 1),
        onCue: () => cueCount += 1,
      );

      for (var cue = 1; cue <= 600; cue += 1) {
        clock.elapsed = Duration(seconds: cue, milliseconds: 20);
        callbacks.removeAt(0)();
      }

      expect(cueCount, 600);
      expect(delays.last, const Duration(milliseconds: 980));
    });

    test('uses an immediate catch-up delay when a cue is already due', () {
      final clock = _FakeTempoClock();
      final delays = <Duration>[];
      final callbacks = <void Function()>[];

      final scheduler = TempoCueScheduler(
        clockFactory: () => clock,
        timerFactory: (duration, callback) {
          delays.add(duration);
          callbacks.add(callback);
          return _ManualTimer();
        },
      );

      scheduler.start(
        interval: const Duration(seconds: 1),
        onCue: () {},
      );

      clock.elapsed = const Duration(milliseconds: 2500);
      callbacks.removeAt(0)();

      expect(delays.last, Duration.zero);
    });
  });
}
