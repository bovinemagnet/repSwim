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
      if (isNewPb(lap.time, lap.distance, session.stroke, combinedPbs)) {
        newPbs.removeWhere(
          (pb) => pb.stroke == session.stroke && pb.distance == lap.distance,
        );
        newPbs.add(PersonalBest(
          id: _uuid.v4(),
          stroke: session.stroke,
          distance: lap.distance,
          bestTime: lap.time,
          achievedAt: session.date,
        ));
      }
    }

    return newPbs;
  }

  /// Returns `true` if [lapTime] is faster than the stored PB for
  /// [stroke] / [distance], or if no PB exists yet.
  static bool isNewPb(
    Duration lapTime,
    int distance,
    String stroke,
    List<PersonalBest> existingPbs,
  ) {
    final existing = existingPbs
        .where((pb) => pb.stroke == stroke && pb.distance == distance)
        .toList();

    if (existing.isEmpty) return true;
    return lapTime < existing.first.bestTime;
  }
}
