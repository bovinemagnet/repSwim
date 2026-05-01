import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/core/utils/duration_utils.dart';

void main() {
  group('DurationUtils.formatDuration', () {
    test('formats seconds only (< 1 minute)', () {
      expect(
        DurationUtils.formatDuration(const Duration(seconds: 45)),
        '0:45',
      );
    });

    test('formats minutes and seconds', () {
      expect(
        DurationUtils.formatDuration(const Duration(minutes: 1, seconds: 5)),
        '1:05',
      );
    });

    test('formats with leading zero on seconds', () {
      expect(
        DurationUtils.formatDuration(const Duration(minutes: 23, seconds: 7)),
        '23:07',
      );
    });

    test('formats hours:minutes:seconds', () {
      expect(
        DurationUtils.formatDuration(
          const Duration(hours: 1, minutes: 23, seconds: 45),
        ),
        '1:23:45',
      );
    });

    test('formats zero duration', () {
      expect(DurationUtils.formatDuration(Duration.zero), '0:00');
    });
  });

  group('DurationUtils.formatDurationWithCentiseconds', () {
    test('formats correctly', () {
      expect(
        DurationUtils.formatDurationWithCentiseconds(
          const Duration(minutes: 1, seconds: 5, milliseconds: 300),
        ),
        '01:05.30',
      );
    });

    test('formats zero', () {
      expect(
        DurationUtils.formatDurationWithCentiseconds(Duration.zero),
        '00:00.00',
      );
    });
  });

  group('DurationUtils.calculatePace', () {
    test('calculates pace per 100m correctly', () {
      // 200m in 4:00 → pace = 2:00/100m
      final pace = DurationUtils.calculatePace(
        const Duration(minutes: 4),
        200,
      );
      expect(pace.inSeconds, closeTo(120, 1));
    });

    test('returns zero for zero distance', () {
      final pace = DurationUtils.calculatePace(
        const Duration(minutes: 2),
        0,
      );
      expect(pace, Duration.zero);
    });

    test('pace for 100m equals total time', () {
      const time = Duration(minutes: 1, seconds: 30);
      final pace = DurationUtils.calculatePace(time, 100);
      expect(pace.inSeconds, time.inSeconds);
    });
  });

  group('DurationUtils.formatPace', () {
    test('formats pace string correctly', () {
      // 100m in 1:30 → 1:30/100m
      final result = DurationUtils.formatPace(
        const Duration(minutes: 1, seconds: 30),
        100,
      );
      expect(result, contains('/100m'));
    });

    test('returns placeholder for zero distance', () {
      expect(
        DurationUtils.formatPace(const Duration(minutes: 1), 0),
        '--:--/100m',
      );
    });
  });
}
