import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rep_swim/database/daos/pb_dao.dart';
import 'package:rep_swim/features/pb/domain/entities/personal_best.dart';
import 'package:rep_swim/features/pb/presentation/providers/pb_providers.dart';
import 'package:rep_swim/features/pb/presentation/screens/pb_screen.dart';

void main() {
  group('PbScreen', () {
    testWidgets('shows empty state when no personal bests exist',
        (tester) async {
      await _pumpPbScreen(tester, const []);

      expect(find.text('No Personal Bests yet'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
    });

    testWidgets('groups PBs by stroke and sorts distances', (tester) async {
      await _pumpPbScreen(tester, [
        _pb(stroke: 'Freestyle', distance: 100, seconds: 62),
        _pb(stroke: 'Backstroke', distance: 50, seconds: 34),
        _pb(stroke: 'Freestyle', distance: 50, seconds: 29),
      ]);

      expect(find.text('Backstroke'), findsOneWidget);
      expect(find.text('Freestyle'), findsOneWidget);
      expect(find.text('50m'), findsNWidgets(2));
      expect(find.text('100m'), findsOneWidget);
      expect(find.text('0:29'), findsOneWidget);
      expect(find.text('1:02'), findsOneWidget);
      expect(find.text('0:58/100m'), findsOneWidget);
    });
  });
}

Future<void> _pumpPbScreen(
  WidgetTester tester,
  List<PersonalBest> pbs,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        personalBestsProvider.overrideWith(
          (ref) => _StaticPersonalBestsNotifier(pbs),
        ),
      ],
      child: const MaterialApp(home: PbScreen()),
    ),
  );
  await tester.pump();
}

PersonalBest _pb({
  required String stroke,
  required int distance,
  required int seconds,
}) {
  return PersonalBest(
    id: '$stroke-$distance',
    stroke: stroke,
    distance: distance,
    bestTime: Duration(seconds: seconds),
    achievedAt: DateTime(2024, 5, distance),
  );
}

class _StaticPersonalBestsNotifier extends PersonalBestsNotifier {
  _StaticPersonalBestsNotifier(List<PersonalBest> pbs)
      : super(_NoopPbDao(), 'profile-1') {
    state = AsyncValue.data(pbs);
  }

  @override
  Future<void> load() async {}
}

class _NoopPbDao extends Mock implements PbDao {}
