import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/core/sync/sync_mode.dart';
import 'package:rep_swim/database/app_database.dart';
import 'package:rep_swim/database/daos/dryland_dao.dart';
import 'package:rep_swim/database/daos/meet_qualification_standard_dao.dart';
import 'package:rep_swim/database/daos/pb_dao.dart';
import 'package:rep_swim/database/daos/qualification_standard_dao.dart';
import 'package:rep_swim/database/daos/race_time_dao.dart';
import 'package:rep_swim/database/daos/swim_session_dao.dart';
import 'package:rep_swim/database/daos/sync_queue_dao.dart';
import 'package:rep_swim/database/daos/training_template_dao.dart';
import 'package:rep_swim/features/dryland/domain/entities/dryland_workout.dart';
import 'package:rep_swim/features/dryland/domain/entities/exercise.dart';
import 'package:rep_swim/features/pb/domain/entities/personal_best.dart';
import 'package:rep_swim/features/race/data/qualification_sources/victorian_metro_sc_2026.dart';
import 'package:rep_swim/features/race/domain/entities/meet_qualification_standard.dart';
import 'package:rep_swim/features/race/domain/entities/qualification_standard.dart';
import 'package:rep_swim/features/race/domain/entities/race_time.dart';
import 'package:rep_swim/features/swim/domain/entities/lap.dart';
import 'package:rep_swim/features/swim/domain/entities/swim_session.dart';
import 'package:rep_swim/features/tempo/domain/entities/tempo_mode.dart';
import 'package:rep_swim/features/tempo/domain/entities/tempo_session_result.dart';
import 'package:rep_swim/features/tempo/domain/entities/tempo_template.dart';
import 'package:rep_swim/features/templates/domain/entities/dryland_routine_template.dart';

void main() {
  group('DAO integration', () {
    late AppDatabase appDb;

    setUp(() {
      appDb = AppDatabase.test();
    });

    tearDown(() async {
      await appDb.close();
    });

    test('swim session insert replaces laps and delete cascades', () async {
      final dao = SwimSessionDao(appDb);
      final session = SwimSession(
        id: 'session-1',
        profileId: 'profile-1',
        date: DateTime.utc(2024),
        totalDistance: 100,
        totalTime: const Duration(seconds: 90),
        stroke: 'Freestyle',
        laps: const [
          Lap(
            id: 'lap-1',
            sessionId: 'session-1',
            profileId: 'profile-1',
            distance: 50,
            time: Duration(seconds: 45),
            lapNumber: 1,
          ),
          Lap(
            id: 'lap-2',
            sessionId: 'session-1',
            profileId: 'profile-1',
            distance: 50,
            time: Duration(seconds: 45),
            lapNumber: 2,
          ),
        ],
      );

      await dao.insertSession(session);
      await dao.insertSession(
        session.copyWith(
          totalDistance: 50,
          totalTime: const Duration(seconds: 40),
          laps: const [
            Lap(
              id: 'lap-3',
              sessionId: 'session-1',
              profileId: 'profile-1',
              distance: 50,
              time: Duration(seconds: 40),
              lapNumber: 1,
            ),
          ],
        ),
      );

      final sessions = await dao.getAllSessions('profile-1');
      expect(sessions.single.laps, hasLength(1));
      expect(sessions.single.laps.single.id, 'lap-3');

      await dao.deleteSession('session-1', 'profile-1');
      expect(await dao.getLapsForSession('session-1', 'profile-1'), isEmpty);
    });

    test('swim session rolls back when a lap insert fails', () async {
      final dao = SwimSessionDao(appDb);
      final session = SwimSession(
        id: 'session-rollback',
        profileId: 'profile-1',
        date: DateTime.utc(2024),
        totalDistance: 50,
        totalTime: const Duration(seconds: 40),
        stroke: 'Freestyle',
        laps: const [
          Lap(
            id: 'lap-bad',
            sessionId: 'missing-session',
            profileId: 'profile-1',
            distance: 50,
            time: Duration(seconds: 40),
            lapNumber: 1,
          ),
        ],
      );

      await expectLater(dao.insertSession(session), throwsA(isA<Exception>()));
      expect(await dao.getAllSessions('profile-1'), isEmpty);
    });

    test('dryland workout update replaces exercises', () async {
      final dao = DrylandDao(appDb);
      final workout = DrylandWorkout(
        id: 'workout-1',
        profileId: 'profile-1',
        date: DateTime.utc(2024),
        exercises: const [
          Exercise(
            id: 'exercise-1',
            workoutId: 'workout-1',
            profileId: 'profile-1',
            name: 'Plank',
            sets: 3,
            reps: 1,
          ),
        ],
      );

      await dao.insertWorkout(workout);
      await dao.insertWorkout(
        workout.copyWith(
          exercises: const [
            Exercise(
              id: 'exercise-2',
              workoutId: 'workout-1',
              profileId: 'profile-1',
              name: 'Dead bug',
              sets: 2,
              reps: 10,
            ),
          ],
        ),
      );

      final workouts = await dao.getAll('profile-1');
      expect(workouts.single.exercises.single.name, 'Dead bug');
    });

    test('template delete cascades routine exercises', () async {
      final dao = TrainingTemplateDao(appDb);
      final now = DateTime.utc(2024);
      final template = DrylandRoutineTemplate(
        id: 'template-1',
        profileId: 'profile-1',
        name: 'Core',
        createdAt: now,
        updatedAt: now,
        exercises: const [
          DrylandRoutineExerciseTemplate(
            id: 'template-exercise-1',
            templateId: 'template-1',
            profileId: 'profile-1',
            name: 'Plank',
            sets: 3,
            reps: 1,
          ),
        ],
      );

      await dao.insertDrylandRoutineTemplate(template);
      await dao.deleteDrylandRoutineTemplate('template-1', 'profile-1');

      expect(
        await dao.getDrylandRoutineExercises('template-1', 'profile-1'),
        isEmpty,
      );
    });

    test('tempo templates and session results persist offline', () async {
      final dao = TrainingTemplateDao(appDb);
      final now = DateTime.utc(2024);
      final template = TempoTemplate(
        id: 'tempo-template-1',
        profileId: 'profile-1',
        name: 'CSS 100s',
        mode: TempoMode.lapPace,
        poolLengthMeters: 25,
        targetDistanceMeters: 100,
        targetTime: const Duration(seconds: 88),
        strokeRate: 72,
        breathEveryStrokes: 3,
        cueSettings: const TempoCueSettings(
          audible: true,
          vibration: true,
          visualFlash: true,
          spoken: false,
          accentEvery: 4,
        ),
        safetyWarningAcknowledged: false,
        createdAt: now,
        updatedAt: now,
      );

      await dao.insertTempoTemplate(template);
      await dao.insertTempoTemplate(
        template.copyWith(
          id: 'tempo-template-2',
          profileId: 'profile-2',
          name: 'Other swimmer tempo',
        ),
      );
      final templates = await dao.getTempoTemplates('profile-1');
      expect(templates.single.name, 'CSS 100s');
      expect(templates.single.cueSettings.vibration, isTrue);
      expect(await dao.getTempoTemplates('profile-2'), hasLength(1));

      final result = TempoSessionResult(
        id: 'tempo-result-1',
        profileId: 'profile-1',
        templateId: template.id,
        mode: TempoMode.lapPace,
        startedAt: now,
        completedAt: now.add(const Duration(minutes: 2)),
        targetDistanceMeters: 100,
        poolLengthMeters: 25,
        targetTime: const Duration(seconds: 88),
        targetStrokeRate: 72,
        actualSplits: const [
          Duration(milliseconds: 22000),
          Duration(milliseconds: 22400),
        ],
        strokeCounts: const [18, 19],
        rpe: 7,
        notes: 'Held rhythm',
      );

      await dao.insertTempoSessionResult(result);
      await dao.insertTempoSessionResult(
        TempoSessionResult(
          id: 'tempo-result-2',
          profileId: 'profile-2',
          mode: TempoMode.lapPace,
          startedAt: now,
          targetDistanceMeters: 100,
          poolLengthMeters: 25,
          targetTime: const Duration(seconds: 88),
          targetStrokeRate: 72,
          actualSplits: const [Duration(milliseconds: 22000)],
          strokeCounts: const [18],
        ),
      );
      await dao.insertTempoSessionResult(
        TempoSessionResult(
          id: 'ramp-result-1',
          profileId: 'profile-1',
          mode: TempoMode.strokeRate,
          startedAt: now.add(const Duration(minutes: 5)),
          targetDistanceMeters: 25,
          poolLengthMeters: 25,
          targetTime: const Duration(seconds: 18),
          targetStrokeRate: 60,
          actualSplits: const [
            Duration(seconds: 18),
            Duration(seconds: 17),
          ],
          strokeCounts: const [18, 20],
          rpe: 6,
          notes: 'Stroke-rate ramp; rep 1: 60.0 spm',
        ),
      );
      final results = await dao.getTempoSessionResults('profile-1');
      expect(results, hasLength(2));
      expect(results.first.id, 'ramp-result-1');
      expect(results.first.strokeCounts, [18, 20]);
      expect(results.first.rpe, 6);
      expect(results.first.notes, contains('Stroke-rate ramp'));
      expect(results.last.templateId, template.id);
      expect(results.last.actualSplits.last.inMilliseconds, 22400);
      expect(results.last.strokeCounts, [18, 19]);
      expect(results.last.notes, 'Held rhythm');
      expect(await dao.getTempoSessionResults('profile-2'), hasLength(1));
    });

    test('sync queue preserves insertion order and increments retry count',
        () async {
      var nextId = 0;
      final dao = SyncQueueDao(
        appDb,
        idFactory: () => 'queue-${nextId++}',
        clock: () => DateTime.utc(2024),
      );

      await dao.enqueue(
        profileId: 'profile-1',
        entityType: 'swim_session',
        entityId: 'one',
        operation: SyncOperation.create,
        payload: const {'id': 'one'},
      );
      await dao.enqueue(
        profileId: 'profile-1',
        entityType: 'swim_session',
        entityId: 'two',
        operation: SyncOperation.create,
        payload: const {'id': 'two'},
      );

      final pending = await dao.getPending(profileId: 'profile-1');
      expect(pending.map((item) => item.entityId), ['one', 'two']);

      await dao.markFailed(pending.first.id, 'network');
      final summary = await dao.getSummary(profileId: 'profile-1');
      final retryable = await dao.getPending(profileId: 'profile-1');
      expect(summary.failed, 1);
      expect(retryable.first.retryCount, 1);
    });

    test('sync queue excludes completed items from pending replay', () async {
      var nextId = 0;
      final dao = SyncQueueDao(
        appDb,
        idFactory: () => 'queue-${nextId++}',
        clock: () => DateTime.utc(2024),
      );

      await dao.enqueue(
        profileId: 'profile-1',
        entityType: 'swim_session',
        entityId: 'one',
        operation: SyncOperation.create,
        payload: const {'id': 'one'},
      );
      await dao.enqueue(
        profileId: 'profile-1',
        entityType: 'swim_session',
        entityId: 'two',
        operation: SyncOperation.update,
        payload: const {'id': 'two'},
      );

      final firstPending = await dao.getPending(profileId: 'profile-1');
      await dao.markComplete(firstPending.first.id);

      final remaining = await dao.getPending(profileId: 'profile-1');
      final summary = await dao.getSummary(profileId: 'profile-1');
      expect(remaining.map((item) => item.entityId), ['two']);
      expect(summary.complete, 1);
      expect(summary.pending, 1);
    });

    test('personal best insertOrUpdate keeps one row per stroke and distance',
        () async {
      final dao = PbDao(appDb);
      await dao.insertOrUpdate(
        PersonalBest(
          id: 'pb-slow',
          profileId: 'profile-1',
          stroke: 'Freestyle',
          distance: 100,
          bestTime: const Duration(seconds: 70),
          achievedAt: DateTime.utc(2024, 1, 1),
        ),
      );
      await dao.insertOrUpdate(
        PersonalBest(
          id: 'pb-fast',
          profileId: 'profile-1',
          stroke: 'Freestyle',
          distance: 100,
          bestTime: const Duration(seconds: 62),
          achievedAt: DateTime.utc(2024, 1, 2),
        ),
      );

      final pbs = await dao.getAll('profile-1');
      expect(pbs, hasLength(1));
      expect(pbs.single.id, 'pb-slow');
      expect(pbs.single.bestTime, const Duration(seconds: 62));
    });

    test('race times insert, update, delete, and stay profile scoped',
        () async {
      final dao = RaceTimeDao(appDb);
      final race = RaceTime(
        id: 'race-1',
        profileId: 'profile-1',
        raceName: 'Club Champs',
        eventDate: DateTime.utc(2024, 5, 1),
        distance: 100,
        stroke: 'Freestyle',
        course: RaceCourse.shortCourseMeters,
        time: const Duration(seconds: 59, milliseconds: 230),
        placement: 3,
        createdAt: DateTime.utc(2024, 5, 1),
        updatedAt: DateTime.utc(2024, 5, 1),
      );
      final otherProfileRace = race.copyWith(
        id: 'race-2',
        profileId: 'profile-2',
      );

      await dao.insertOrUpdate(race);
      await dao.insertOrUpdate(otherProfileRace);
      await dao.insertOrUpdate(
        race.copyWith(
          raceName: 'State Sprint',
          time: const Duration(seconds: 58, milliseconds: 910),
        ),
      );

      final profileOneRaces = await dao.getAll('profile-1');
      final profileTwoRaces = await dao.getAll('profile-2');
      expect(profileOneRaces, hasLength(1));
      expect(profileOneRaces.single.raceName, 'State Sprint');
      expect(profileOneRaces.single.time.inMilliseconds, 58910);
      expect(profileTwoRaces.single.id, 'race-2');

      await dao.delete('race-1', 'profile-1');
      expect(await dao.getAll('profile-1'), isEmpty);
      expect(await dao.getAll('profile-2'), hasLength(1));
    });

    test(
        'qualification standards insert, update, delete, and stay profile scoped',
        () async {
      final dao = QualificationStandardDao(appDb);
      final standard = QualificationStandard(
        id: 'standard-1',
        profileId: 'profile-1',
        age: 12,
        distance: 50,
        stroke: 'Freestyle',
        course: RaceCourse.shortCourseMeters,
        goldTime: const Duration(seconds: 30),
        silverTime: const Duration(seconds: 32),
        bronzeTime: const Duration(seconds: 35),
        createdAt: DateTime.utc(2024, 5, 1),
        updatedAt: DateTime.utc(2024, 5, 1),
      );
      final otherProfileStandard = standard.copyWith(
        id: 'standard-2',
        profileId: 'profile-2',
      );

      await dao.insertOrUpdate(standard);
      await dao.insertOrUpdate(otherProfileStandard);
      await dao.insertOrUpdate(
        standard.copyWith(
          distance: 100,
          bronzeTime: const Duration(seconds: 70),
        ),
      );

      final profileOneStandards = await dao.getAll('profile-1');
      final profileTwoStandards = await dao.getAll('profile-2');
      expect(profileOneStandards, hasLength(1));
      expect(profileOneStandards.single.distance, 100);
      expect(
          profileOneStandards.single.bronzeTime, const Duration(seconds: 70));
      expect(profileTwoStandards.single.id, 'standard-2');

      await dao.delete('standard-1', 'profile-1');
      expect(await dao.getAll('profile-1'), isEmpty);
      expect(await dao.getAll('profile-2'), hasLength(1));
    });

    test('meet qualification standards import and replace by source', () async {
      final dao = MeetQualificationStandardDao(appDb);
      final standards = victorianMetroSc2026QualifyingStandards();

      await dao.replaceSource(victorianMetroSc2026SourceName, standards);

      final imported = await dao.getAll(
        sourceName: victorianMetroSc2026SourceName,
      );
      expect(imported, hasLength(92));
      final maleFreestyle = imported.singleWhere(
        (standard) =>
            standard.sex == QualificationSex.male &&
            standard.ageGroupLabel == '14 - 15 Years' &&
            standard.distance == 100 &&
            standard.stroke == 'Freestyle',
      );
      expect(maleFreestyle.qualifyingCentiseconds, 5962);
      expect(maleFreestyle.validFrom, DateTime.utc(2025, 7, 26));

      await dao.replaceSource(
        victorianMetroSc2026SourceName,
        standards.take(1).toList(),
      );

      final replaced = await dao.getAll(
        sourceName: victorianMetroSc2026SourceName,
      );
      expect(replaced, hasLength(1));
      expect(replaced.single.sourceName, victorianMetroSc2026SourceName);
    });
  });
}
