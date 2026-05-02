import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rep_swim/database/daos/meet_qualification_standard_dao.dart';
import 'package:rep_swim/database/daos/qualification_standard_dao.dart';
import 'package:rep_swim/features/race/data/qualification_sources/victorian_metro_sc_2026.dart';
import 'package:rep_swim/features/race/domain/entities/meet_qualification_standard.dart';
import 'package:rep_swim/features/race/domain/entities/qualification_standard.dart';
import 'package:rep_swim/features/race/domain/entities/race_time.dart';
import 'package:rep_swim/features/race/presentation/providers/qualification_standard_providers.dart';
import 'package:rep_swim/features/race/presentation/screens/qualification_standards_screen.dart';

void main() {
  group('QualificationStandardsScreen', () {
    testWidgets('shows empty state', (tester) async {
      await _pumpStandards(tester, []);

      expect(find.text('Qualification Standards'), findsOneWidget);
      expect(
          find.text('No qualification standards configured.'), findsOneWidget);
    });

    testWidgets('imports Victorian Metro SC standards', (tester) async {
      await _pumpStandards(tester, []);

      await tester.tap(find.byTooltip('Import Victorian Metro SC standards'));
      await tester.pumpAndSettle();

      expect(find.text('Imported meet standards'), findsOneWidget);
      expect(find.text('Male 50m Butterfly'), findsWidgets);
      expect(find.text('00:44.30'), findsOneWidget);
      expect(
        find.text(
          'Imported 92 standards from $victorianMetroSc2026SourceName.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('adds a qualification standard', (tester) async {
      await _pumpStandards(tester, []);

      await tester.tap(find.text('Add Standard'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Age'), '12');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Distance (m)'),
        '50',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Gold time (csec)'),
        '3000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Silver time (csec)'),
        '3200',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bronze time (csec)'),
        '3500',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.text('Age 12 - 50m Freestyle'), findsOneWidget);
      expect(find.text('Gold: 00:30.00'), findsOneWidget);
      expect(find.text('Silver: 00:32.00'), findsOneWidget);
      expect(find.text('Bronze: 00:35.00'), findsOneWidget);
    });

    testWidgets('validates medal order', (tester) async {
      await _pumpStandards(tester, []);

      await tester.tap(find.text('Add Standard'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Gold time (csec)'),
        '3300',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Silver time (csec)'),
        '3200',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bronze time (csec)'),
        '3500',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pump();

      expect(find.text('Gold must be fastest'), findsOneWidget);
    });

    testWidgets('edits and deletes a standard', (tester) async {
      await _pumpStandards(tester, [_standard()]);

      await tester.tap(find.byTooltip('Edit qualification standard'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Distance (m)'),
        '100',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Age 12 - 100m Freestyle'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete qualification standard'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(
          find.text('No qualification standards configured.'), findsOneWidget);
    });
  });
}

Future<void> _pumpStandards(
  WidgetTester tester,
  List<QualificationStandard> standards,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        qualificationStandardsProvider.overrideWith(
          (ref) => _MutableStandardsNotifier(standards),
        ),
        meetQualificationStandardsProvider.overrideWith(
          (ref) => _MutableMeetStandardsNotifier(),
        ),
      ],
      child: const MaterialApp(home: QualificationStandardsScreen()),
    ),
  );
  await tester.pump();
}

QualificationStandard _standard() {
  return QualificationStandard(
    id: 'standard-1',
    profileId: 'profile-1',
    age: 12,
    distance: 50,
    stroke: 'Freestyle',
    course: RaceCourse.shortCourseMeters,
    goldTime: const Duration(seconds: 30),
    silverTime: const Duration(seconds: 32),
    bronzeTime: const Duration(seconds: 35),
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
  );
}

class _MutableStandardsNotifier extends QualificationStandardsNotifier {
  _MutableStandardsNotifier(List<QualificationStandard> standards)
      : _standards = [...standards],
        super(_NoopQualificationStandardDao(), 'profile-1') {
    state = AsyncValue.data([..._standards]);
  }

  final List<QualificationStandard> _standards;
  int _nextId = 0;

  @override
  Future<void> load() async {
    state = AsyncValue.data([..._standards]);
  }

  @override
  Future<QualificationStandard> addStandard({
    required int age,
    required int distance,
    required String stroke,
    required RaceCourse course,
    required Duration goldTime,
    required Duration silverTime,
    required Duration bronzeTime,
  }) async {
    final standard = QualificationStandard(
      id: 'created-${++_nextId}',
      profileId: 'profile-1',
      age: age,
      distance: distance,
      stroke: stroke,
      course: course,
      goldTime: goldTime,
      silverTime: silverTime,
      bronzeTime: bronzeTime,
      createdAt: DateTime.utc(2024),
      updatedAt: DateTime.utc(2024),
    );
    _standards.add(standard);
    await load();
    return standard;
  }

  @override
  Future<void> updateStandard(QualificationStandard standard) async {
    final index = _standards.indexWhere((item) => item.id == standard.id);
    if (index >= 0) {
      _standards[index] = standard;
    }
    await load();
  }

  @override
  Future<void> deleteStandard(String id) async {
    _standards.removeWhere((standard) => standard.id == id);
    await load();
  }
}

class _NoopQualificationStandardDao extends Mock
    implements QualificationStandardDao {}

class _MutableMeetStandardsNotifier extends MeetQualificationStandardsNotifier {
  _MutableMeetStandardsNotifier()
      : _standards = [],
        super(_NoopMeetQualificationStandardDao()) {
    state = const AsyncValue.data([]);
  }

  final List<MeetQualificationStandard> _standards;

  @override
  Future<void> load() async {
    state = AsyncValue.data([..._standards]);
  }

  @override
  Future<int> importVictorianMetroSc2026() async {
    final standards = victorianMetroSc2026QualifyingStandards();
    _standards
      ..clear()
      ..addAll(standards);
    await load();
    return standards.length;
  }
}

class _NoopMeetQualificationStandardDao extends Mock
    implements MeetQualificationStandardDao {}
