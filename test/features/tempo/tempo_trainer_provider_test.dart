import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/tempo/domain/entities/tempo_mode.dart';
import 'package:rep_swim/features/tempo/domain/entities/tempo_template.dart';
import 'package:rep_swim/features/tempo/presentation/providers/tempo_cue_player.dart';
import 'package:rep_swim/features/tempo/presentation/providers/tempo_trainer_provider.dart';

class _FakeTempoCuePlayer implements TempoCuePlayer {
  final cues = <bool>[];

  @override
  Future<void> playCue({
    required TempoCueSettings settings,
    required bool accent,
  }) async {
    cues.add(accent);
  }
}

void main() {
  group('TempoTrainerNotifier', () {
    test('plays audible/vibration cue on start and accents configured beats',
        () {
      fakeAsync((async) {
        final cuePlayer = _FakeTempoCuePlayer();
        final notifier = TempoTrainerNotifier(cuePlayer);

        notifier.configure(
          mode: TempoMode.strokeRate,
          poolLengthMeters: 25,
          targetDistanceMeters: 100,
          targetTime: const Duration(seconds: 90),
          strokeRate: 60,
          breathEveryStrokes: 3,
          cueSettings: const TempoCueSettings(
            audible: true,
            vibration: true,
            visualFlash: true,
            accentEvery: 2,
          ),
          safetyWarningAcknowledged: false,
        );

        notifier.start();
        async.elapse(const Duration(seconds: 2));

        expect(cuePlayer.cues, [false, true, false]);
        expect(notifier.state.beatCount, 3);
        expect(notifier.state.flashActive, isTrue);

        notifier.dispose();
      });
    });

    test('breath pattern cue interval follows stroke rate and breath count',
        () {
      final notifier = TempoTrainerNotifier(_FakeTempoCuePlayer());

      notifier.configure(
        mode: TempoMode.breathPattern,
        poolLengthMeters: 25,
        targetDistanceMeters: 100,
        targetTime: const Duration(seconds: 90),
        strokeRate: 60,
        breathEveryStrokes: 3,
        cueSettings: const TempoCueSettings(),
        safetyWarningAcknowledged: false,
      );

      expect(notifier.state.cueInterval, const Duration(seconds: 3));
      notifier.dispose();
    });
  });
}
