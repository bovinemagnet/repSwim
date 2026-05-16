import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_report.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share_category.dart';
import 'package:rep_swim/features/coach/presentation/providers/coach_providers.dart';
import 'package:rep_swim/features/coach/presentation/providers/coach_report_providers.dart';
import 'package:rep_swim/features/coach/presentation/screens/coach_view_screen.dart';
import 'package:rep_swim/features/profiles/domain/entities/swimmer_profile.dart';

void main() {
  const someProfileId = 'test-profile-001';

  final fixedProfile = SwimmerProfile(
    id: someProfileId,
    displayName: 'Test Swimmer',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  final fixedReport = CoachReport(
    profile: fixedProfile,
    includedCategories: const {CoachShareCategory.swimSessions},
    swimSessions: const [],
    raceTimes: null,
  );

  testWidgets('shows swim sessions panel when included in report',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedProfileIdsProvider.overrideWith(
            (ref) async => [someProfileId],
          ),
          coachReportProvider(someProfileId).overrideWith(
            (ref) async => fixedReport,
          ),
        ],
        child: const MaterialApp(
          home: CoachViewScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Swim sessions'), findsOneWidget);
  });

  testWidgets('does not show race times panel when not in report',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedProfileIdsProvider.overrideWith(
            (ref) async => [someProfileId],
          ),
          coachReportProvider(someProfileId).overrideWith(
            (ref) async => fixedReport,
          ),
        ],
        child: const MaterialApp(
          home: CoachViewScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Race times'), findsNothing);
  });

  testWidgets('shows no edit or delete icons (read-only screen)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedProfileIdsProvider.overrideWith(
            (ref) async => [someProfileId],
          ),
          coachReportProvider(someProfileId).overrideWith(
            (ref) async => fixedReport,
          ),
        ],
        child: const MaterialApp(
          home: CoachViewScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
  });

  testWidgets('shows message when no profiles are shared', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedProfileIdsProvider.overrideWith(
            (ref) async => <String>[],
          ),
        ],
        child: const MaterialApp(
          home: CoachViewScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No profiles are shared with a coach'), findsOneWidget);
  });
}
