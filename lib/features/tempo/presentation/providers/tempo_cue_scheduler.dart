import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef TempoTimerFactory = Timer Function(
  Duration duration,
  void Function() callback,
);

abstract class TempoClock {
  Duration get elapsed;
  void start();
  void stop();
  void reset();
}

class StopwatchTempoClock implements TempoClock {
  final Stopwatch _stopwatch = Stopwatch();

  @override
  Duration get elapsed => _stopwatch.elapsed;

  @override
  void start() => _stopwatch.start();

  @override
  void stop() => _stopwatch.stop();

  @override
  void reset() => _stopwatch.reset();
}

class TempoCueScheduler {
  TempoCueScheduler({
    TempoTimerFactory? timerFactory,
    TempoClock Function()? clockFactory,
  })  : _timerFactory = timerFactory ?? Timer.new,
        _clockFactory = clockFactory ?? StopwatchTempoClock.new;

  final TempoTimerFactory _timerFactory;
  final TempoClock Function() _clockFactory;

  TempoClock? _clock;
  Timer? _timer;
  Duration _interval = Duration.zero;
  int _nextCueIndex = 1;
  void Function()? _onCue;

  bool get isRunning => _clock != null;

  void start({
    required Duration interval,
    required void Function() onCue,
  }) {
    if (interval <= Duration.zero) {
      throw ArgumentError.value(interval, 'interval', 'must be positive');
    }

    stop();
    _interval = interval;
    _onCue = onCue;
    _nextCueIndex = 1;
    _clock = _clockFactory()
      ..reset()
      ..start();
    _scheduleNextCue();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _clock?.stop();
    _clock = null;
    _onCue = null;
    _nextCueIndex = 1;
  }

  void _scheduleNextCue() {
    final clock = _clock;
    if (clock == null) return;

    final targetElapsed = _interval * _nextCueIndex;
    final delay = targetElapsed - clock.elapsed;
    _timer = _timerFactory(
      delay.isNegative ? Duration.zero : delay,
      _handleCue,
    );
  }

  void _handleCue() {
    if (_clock == null) return;

    _onCue?.call();
    _nextCueIndex += 1;
    _scheduleNextCue();
  }
}

final tempoCueSchedulerProvider = Provider<TempoCueScheduler>(
  (ref) => TempoCueScheduler(),
);
