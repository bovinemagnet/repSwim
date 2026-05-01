import 'package:uuid/uuid.dart';
import '../../domain/entities/personal_best.dart';
import '../../../swim/domain/entities/swim_session.dart';

class PbService {
  PbService._();

  static const _uuid = Uuid();

  /// Checks every lap in [session] against [existingPbs] and returns a list
  /// of new [PersonalBest] records for any lap that beats the current best.
  static List<PersonalBest> detectNewPbs(
    SwimSession session,
    List<PersonalBest> existingPbs,
  ) {
    final newPbs = <PersonalBest>[];

    for (final lap in session.laps) {
      // Check against both existing DB PBs and any new PBs found so far in
      // this session, so a slower later lap cannot overwrite a faster earlier one.
      final combinedPbs = [...existingPbs, ...newPbs];
      if (isNewPb(
        lap.time,
        lap.distance,
        session.stroke,
        combinedPbs,
        profileId: session.profileId,
      )) {
        newPbs.removeWhere(
          (pb) =>
              pb.profileId == session.profileId &&
              pb.stroke == session.stroke &&
              pb.distance == lap.distance,
        );
        newPbs.add(PersonalBest(
          id: _uuid.v4(),
          profileId: session.profileId,
          stroke: session.stroke,
          distance: lap.distance,
          bestTime: lap.time,
          achievedAt: session.date,
        ));
      }
    }

    return newPbs;
  }

  static List<PersonalBest> rebuildFromSessions(List<SwimSession> sessions) {
    final orderedSessions = [...sessions]
      ..sort((a, b) => a.date.compareTo(b.date));
    final rebuilt = <PersonalBest>[];

    for (final session in orderedSessions) {
      final newPbs = detectNewPbs(session, rebuilt);
      for (final pb in newPbs) {
        rebuilt.removeWhere(
          (existing) =>
              existing.profileId == pb.profileId &&
              existing.stroke == pb.stroke &&
              existing.distance == pb.distance,
        );
        rebuilt.add(pb);
      }
    }

    return rebuilt;
  }

  /// Returns `true` if [lapTime] is faster than the stored PB for
  /// [stroke] / [distance], or if no PB exists yet.
  static bool isNewPb(
    Duration lapTime,
    int distance,
    String stroke,
    List<PersonalBest> existingPbs, {
    String? profileId,
  }) {
    final existing = existingPbs
        .where((pb) =>
            (profileId == null || pb.profileId == profileId) &&
            pb.stroke == stroke &&
            pb.distance == distance)
        .toList();

    if (existing.isEmpty) return true;
    return lapTime < existing.first.bestTime;
  }
}
