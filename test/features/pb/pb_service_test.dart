import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/pb/domain/entities/personal_best.dart';
import 'package:rep_swim/features/pb/domain/services/pb_service.dart';
import 'package:rep_swim/features/swim/domain/entities/swim_session.dart';
import 'package:rep_swim/features/swim/domain/entities/lap.dart';

PersonalBest _makePb({
  required String stroke,
  required int distance,
  required Duration bestTime,
}) {
  return PersonalBest(
    id: 'pb-$stroke-$distance',
    stroke: stroke,
    distance: distance,
    bestTime: bestTime,
    achievedAt: DateTime(2024, 1, 1),
  );
}

SwimSession _makeSession({
  required String stroke,
  required List<Lap> laps,
}) {
  return SwimSession(
    id: 'session-1',
    date: DateTime(2024, 6, 1),
    totalDistance: laps.fold(0, (s, l) => s + l.distance),
    totalTime: laps.fold(Duration.zero, (s, l) => s + l.time),
    stroke: stroke,
    laps: laps,
  );
}

Lap _makeLap(int lapNumber, int distance, Duration time) => Lap(
      id: 'lap-$lapNumber',
      sessionId: 'session-1',
      distance: distance,
      time: time,
      lapNumber: lapNumber,
    );

void main() {
  group('PbService.isNewPb', () {
    test('returns true when no existing PBs', () {
      expect(
        PbService.isNewPb(
          const Duration(seconds: 60),
          100,
          'Freestyle',
          [],
        ),
        isTrue,
      );
    });

    test('returns true when new time is faster', () {
      final existing = [
        _makePb(
            stroke: 'Freestyle',
            distance: 100,
            bestTime: const Duration(seconds: 65)),
      ];
      expect(
        PbService.isNewPb(
          const Duration(seconds: 60),
          100,
          'Freestyle',
          existing,
        ),
        isTrue,
      );
    });

    test('returns false when new time is slower', () {
      final existing = [
        _makePb(
            stroke: 'Freestyle',
            distance: 100,
            bestTime: const Duration(seconds: 55)),
      ];
      expect(
        PbService.isNewPb(
          const Duration(seconds: 60),
          100,
          'Freestyle',
          existing,
        ),
        isFalse,
      );
    });

    test('returns false when new time equals existing PB', () {
      final existing = [
        _makePb(
            stroke: 'Freestyle',
            distance: 100,
            bestTime: const Duration(seconds: 60)),
      ];
      expect(
        PbService.isNewPb(
          const Duration(seconds: 60),
          100,
          'Freestyle',
          existing,
        ),
        isFalse,
      );
    });

    test('returns true when stroke differs from existing PB', () {
      final existing = [
        _makePb(
            stroke: 'Backstroke',
            distance: 100,
            bestTime: const Duration(seconds: 50)),
      ];
      // Freestyle has no PB
      expect(
        PbService.isNewPb(
          const Duration(seconds: 55),
          100,
          'Freestyle',
          existing,
        ),
        isTrue,
      );
    });

    test('returns true when distance differs from existing PB', () {
      final existing = [
        _makePb(
            stroke: 'Freestyle',
            distance: 200,
            bestTime: const Duration(seconds: 130)),
      ];
      // 100m has no PB
      expect(
        PbService.isNewPb(
          const Duration(seconds: 60),
          100,
          'Freestyle',
          existing,
        ),
        isTrue,
      );
    });
  });

  group('PbService.detectNewPbs', () {
    test('detects a new PB when no existing PBs', () {
      final session = _makeSession(
        stroke: 'Freestyle',
        laps: [_makeLap(1, 100, const Duration(seconds: 58))],
      );
      final newPbs = PbService.detectNewPbs(session, []);
      expect(newPbs.length, 1);
      expect(newPbs.first.stroke, 'Freestyle');
      expect(newPbs.first.distance, 100);
      expect(newPbs.first.bestTime, const Duration(seconds: 58));
    });

    test('detects no PBs when all laps are slower', () {
      final existing = [
        _makePb(
            stroke: 'Freestyle',
            distance: 100,
            bestTime: const Duration(seconds: 50)),
      ];
      final session = _makeSession(
        stroke: 'Freestyle',
        laps: [_makeLap(1, 100, const Duration(seconds: 60))],
      );
      expect(PbService.detectNewPbs(session, existing), isEmpty);
    });

    test('detects PBs for multiple laps', () {
      final session = _makeSession(
        stroke: 'Backstroke',
        laps: [
          _makeLap(1, 50, const Duration(seconds: 30)),
          _makeLap(2, 100, const Duration(seconds: 65)),
        ],
      );
      final newPbs = PbService.detectNewPbs(session, []);
      expect(newPbs.length, 2);
    });

    test('deduplicates PBs for same distance in one session', () {
      // Two laps at same distance — only the faster one should win (second lap faster)
      final session = _makeSession(
        stroke: 'Freestyle',
        laps: [
          _makeLap(1, 50, const Duration(seconds: 32)),
          _makeLap(2, 50, const Duration(seconds: 28)), // faster
        ],
      );
      final newPbs = PbService.detectNewPbs(session, []);
      expect(newPbs.length, 1);
      expect(newPbs.first.bestTime, const Duration(seconds: 28));
    });

    test('keeps faster lap when it comes first in session', () {
      // First lap is faster — slower second lap must not overwrite it
      final session = _makeSession(
        stroke: 'Freestyle',
        laps: [
          _makeLap(1, 50, const Duration(seconds: 28)), // faster first
          _makeLap(2, 50, const Duration(seconds: 32)),
        ],
      );
      final newPbs = PbService.detectNewPbs(session, []);
      expect(newPbs.length, 1);
      expect(newPbs.first.bestTime, const Duration(seconds: 28));
    });

    test('does not detect PB for a lap that does not beat existing', () {
      final existing = [
        _makePb(
            stroke: 'Freestyle',
            distance: 50,
            bestTime: const Duration(seconds: 25)),
      ];
      final session = _makeSession(
        stroke: 'Freestyle',
        laps: [_makeLap(1, 50, const Duration(seconds: 27))],
      );
      expect(PbService.detectNewPbs(session, existing), isEmpty);
    });
  });
}
