import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/stopwatch/presentation/providers/stopwatch_provider.dart';

void main() {
  group('StopwatchState', () {
    test('copyWith can clear startedAt', () {
      final startedAt = DateTime(2024, 1, 1);
      final state = StopwatchState(startedAt: startedAt);

      final updated = state.copyWith(clearStartedAt: true);

      expect(updated.startedAt, isNull);
    });
  });
}
