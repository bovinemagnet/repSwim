import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rep_swim/database/daos/race_time_dao.dart';
import 'package:rep_swim/features/profiles/domain/entities/swimmer_profile.dart';
import 'package:rep_swim/features/profiles/presentation/providers/profile_providers.dart';
import 'package:rep_swim/features/race/domain/entities/race_time.dart';
import 'package:rep_swim/features/race/presentation/providers/race_time_providers.dart';
import 'package:rep_swim/features/race/presentation/screens/race_times_screen.dart';

void main() {
  group('RaceTimesScreen', () {
    testWidgets('shows empty state', (tester) async {
      await _pumpRaceTimes(tester, []);

      expect(find.text('Race Times'), findsOneWidget);
      expect(find.text('No race times match your filters'), findsOneWidget);
    });

    testWidgets('adds a race time with validated official time',
        (tester) async {
      await _pumpRaceTimes(tester, []);

      await tester.tap(find.text('Add Race'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Race or meet'),
        'State Sprint',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Distance (m)'),
        '50',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Min'), '0');
      await tester.enterText(find.widgetWithText(TextFormField, 'Sec'), '28');
      await tester.enterText(find.widgetWithText(TextFormField, 'Csec'), '45');
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.text('50m Freestyle'), findsOneWidget);
      expect(find.textContaining('State Sprint - Short course meters'),
          findsOneWidget);
      expect(find.text('00:28.45'), findsOneWidget);
    });

    testWidgets('validates required race name and non-zero time',
        (tester) async {
      await _pumpRaceTimes(tester, []);

      await tester.tap(find.text('Add Race'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pump();

      expect(find.text('Required'), findsOneWidget);
      expect(find.text('Enter time'), findsOneWidget);
    });

    testWidgets('filters race times by search text', (tester) async {
      await _pumpRaceTimes(tester, [
        _race(id: 'race-1', raceName: 'State Sprint'),
        _race(id: 'race-2', raceName: 'Club Night'),
      ]);

      expect(find.textContaining('State Sprint - Short course meters'),
          findsOneWidget);
      expect(find.textContaining('Club Night - Short course meters'),
          findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'state');
      await tester.pump();

      expect(find.textContaining('State Sprint - Short course meters'),
          findsOneWidget);
      expect(find.textContaining('Club Night - Short course meters'),
          findsNothing);
    });

    testWidgets('edits and deletes race times', (tester) async {
      await _pumpRaceTimes(tester, [_race(id: 'race-1')]);

      await tester.tap(find.byTooltip('Edit race time'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Race or meet'),
        'Updated Meet',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Updated Meet - Short course meters'),
          findsOneWidget);

      await tester.tap(find.byTooltip('Delete race time'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Updated Meet - Short course meters'),
          findsNothing);
      expect(find.text('No race times match your filters'), findsOneWidget);
    });
  });
}

Future<void> _pumpRaceTimes(
  WidgetTester tester,
  List<RaceTime> raceTimes,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentProfileProvider.overrideWithValue(
          SwimmerProfile(
            id: 'profile-1',
            displayName: 'Sophie',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
        ),
        raceTimesProvider.overrideWith(
          (ref) => _MutableRaceTimesNotifier(raceTimes),
        ),
      ],
      child: const MaterialApp(home: RaceTimesScreen()),
    ),
  );
  await tester.pump();
}

RaceTime _race({
  required String id,
  String raceName = 'Club Champs',
}) {
  return RaceTime(
    id: id,
    profileId: 'profile-1',
    raceName: raceName,
    eventDate: DateTime(2024, 5, 1),
    distance: 100,
    stroke: 'Freestyle',
    course: RaceCourse.shortCourseMeters,
    time: const Duration(seconds: 58, milliseconds: 210),
    createdAt: DateTime(2024, 5, 1),
    updatedAt: DateTime(2024, 5, 1),
  );
}

class _MutableRaceTimesNotifier extends RaceTimesNotifier {
  _MutableRaceTimesNotifier(List<RaceTime> raceTimes)
      : _raceTimes = [...raceTimes],
        super(_NoopRaceTimeDao(), 'profile-1') {
    state = AsyncValue.data([..._raceTimes]);
  }

  final List<RaceTime> _raceTimes;
  int _nextId = 0;

  @override
  Future<void> load() async {
    state = AsyncValue.data([..._raceTimes]);
  }

  @override
  Future<RaceTime> addRaceTime({
    required String raceName,
    required DateTime eventDate,
    required int distance,
    required String stroke,
    required RaceCourse course,
    required Duration time,
    String? notes,
    int? placement,
    String? location,
  }) async {
    final raceTime = RaceTime(
      id: 'created-${++_nextId}',
      profileId: 'profile-1',
      raceName: raceName,
      eventDate: eventDate,
      distance: distance,
      stroke: stroke,
      course: course,
      time: time,
      notes: notes,
      placement: placement,
      location: location,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
    _raceTimes.add(raceTime);
    await load();
    return raceTime;
  }

  @override
  Future<void> updateRaceTime(RaceTime raceTime) async {
    final index = _raceTimes.indexWhere((item) => item.id == raceTime.id);
    if (index >= 0) {
      _raceTimes[index] = raceTime;
    }
    await load();
  }

  @override
  Future<void> deleteRaceTime(String id) async {
    _raceTimes.removeWhere((raceTime) => raceTime.id == id);
    await load();
  }
}

class _NoopRaceTimeDao extends Mock implements RaceTimeDao {}
