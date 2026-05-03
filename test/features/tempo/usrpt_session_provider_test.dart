import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/tempo/presentation/providers/usrpt_session_provider.dart';

void main() {
  group('UsrptSessionNotifier', () {
    test('tracks pass and fail outcomes and stops at fail rule', () {
      final notifier = UsrptSessionNotifier();

      notifier.configure(
        eventDistanceMeters: 100,
        eventTargetTime: const Duration(seconds: 60),
        repetitionDistanceMeters: 25,
        restDuration: const Duration(seconds: 20),
        failLimit: 2,
      );

      notifier.logPass();
      notifier.tickRest(const Duration(seconds: 5));
      notifier.logFail();
      notifier.logFail();
      notifier.logPass();

      expect(notifier.state.outcomes.map((outcome) => outcome.label), [
        'P',
        'F',
        'F',
      ]);
      expect(notifier.state.passCount, 1);
      expect(notifier.state.failCount, 2);
      expect(notifier.state.failRuleReached, isTrue);
      expect(notifier.state.restRemaining, Duration.zero);
      expect(notifier.state.lastStatus, 'Fail rule reached after 2 fails.');
    });

    test('resets outcomes without changing configured preset', () {
      final notifier = UsrptSessionNotifier();

      notifier.configure(
        eventDistanceMeters: 200,
        eventTargetTime: const Duration(seconds: 130),
        repetitionDistanceMeters: 50,
        restDuration: const Duration(seconds: 25),
        failLimit: 3,
      );
      notifier.logPass();
      notifier.resetOutcomes();

      expect(notifier.state.outcomes, isEmpty);
      expect(notifier.state.preset.repetitionTargetTime,
          const Duration(milliseconds: 32500));
      expect(notifier.state.failRuleReached, isFalse);
    });
  });
}
