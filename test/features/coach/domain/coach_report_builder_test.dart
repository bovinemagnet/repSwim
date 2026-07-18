import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/database/app_database.dart';
import 'package:rep_swim/database/daos/dryland_dao.dart';
import 'package:rep_swim/database/daos/pb_dao.dart';
import 'package:rep_swim/database/daos/profile_dao.dart';
import 'package:rep_swim/database/daos/race_time_dao.dart';
import 'package:rep_swim/database/daos/swim_session_dao.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share_category.dart';
import 'package:rep_swim/features/coach/domain/services/coach_report_builder.dart';
import 'package:rep_swim/features/profiles/domain/entities/swimmer_profile.dart';
import 'package:rep_swim/features/race/domain/entities/race_time.dart';
import 'package:rep_swim/features/swim/domain/entities/swim_session.dart';

void main() {
  late AppDatabase db;
  late ProfileDao profileDao;
  late SwimSessionDao sessionDao;
  late RaceTimeDao raceTimeDao;
  late PbDao pbDao;
  late DrylandDao drylandDao;
  late CoachReportBuilder builder;

  setUp(() async {
    db = AppDatabase.test();
    profileDao = ProfileDao(db);
    sessionDao = SwimSessionDao(db);
    raceTimeDao = RaceTimeDao(db);
    pbDao = PbDao(db);
    drylandDao = DrylandDao(db);
    builder = CoachReportBuilder(
      profileDao: profileDao,
      sessionDao: sessionDao,
      raceTimeDao: raceTimeDao,
      pbDao: pbDao,
      drylandDao: drylandDao,
    );

    // Seed profile p1.
    final now = DateTime.utc(2025, 1, 1);
    await profileDao.insert(SwimmerProfile(
      id: 'p1',
      displayName: 'Alice',
      createdAt: now,
      updatedAt: now,
    ));

    // Seed profile p2.
    await profileDao.insert(SwimmerProfile(
      id: 'p2',
      displayName: 'Bob',
      createdAt: now,
      updatedAt: now,
    ));

    // Swim session for p1.
    await sessionDao.insertSession(SwimSession(
      id: 's1',
      profileId: 'p1',
      date: DateTime.utc(2025, 1, 1),
      totalDistance: 1000,
      totalTime: const Duration(minutes: 20),
      stroke: 'freestyle',
      laps: const [],
    ));

    // Swim session for p2.
    await sessionDao.insertSession(SwimSession(
      id: 's2',
      profileId: 'p2',
      date: DateTime.utc(2025, 1, 2),
      totalDistance: 500,
      totalTime: const Duration(minutes: 10),
      stroke: 'backstroke',
      laps: const [],
    ));

    // Race time for p1.
    final ts = DateTime.utc(2025, 1, 1);
    await raceTimeDao.insertOrUpdate(RaceTime(
      id: 'r1',
      profileId: 'p1',
      raceName: 'Club Champs',
      eventDate: ts,
      distance: 100,
      stroke: 'freestyle',
      course: RaceCourse.shortCourseMeters,
      time: const Duration(seconds: 60),
      createdAt: ts,
      updatedAt: ts,
    ));
  });

  tearDown(() => db.close());

  test('only shared categories are loaded', () async {
    const share = CoachShare(
      profileId: 'p1',
      enabled: true,
      sharedCategories: {CoachShareCategory.swimSessions},
    );

    final report = await builder.build('p1', share);

    expect(report.includes(CoachShareCategory.swimSessions), isTrue);
    expect(report.swimSessions, isNotNull);
    expect(report.includes(CoachShareCategory.raceTimes), isFalse);
    expect(report.raceTimes, isNull);
    expect(report.includes(CoachShareCategory.personalBests), isFalse);
    expect(report.personalBests, isNull);
    expect(report.includes(CoachShareCategory.dryland), isFalse);
    expect(report.drylandWorkouts, isNull);
    expect(report.includes(CoachShareCategory.analytics), isFalse);
    expect(report.analytics, isNull);
  });

  test('report is scoped to the requested profile', () async {
    const share = CoachShare(
      profileId: 'p1',
      enabled: true,
      sharedCategories: {CoachShareCategory.swimSessions},
    );

    final report = await builder.build('p1', share);

    expect(report.swimSessions, isNotNull);
    for (final session in report.swimSessions!) {
      expect(session.profileId, 'p1');
    }
  });
}
