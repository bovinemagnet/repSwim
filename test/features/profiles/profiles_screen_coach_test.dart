import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/core/constants/app_constants.dart';
import 'package:rep_swim/features/coach/presentation/providers/coach_providers.dart';
import 'package:rep_swim/features/profiles/domain/entities/swimmer_profile.dart';
import 'package:rep_swim/features/profiles/presentation/providers/profile_providers.dart';
import 'package:rep_swim/features/profiles/presentation/providers/profile_summary_providers.dart';
import 'package:rep_swim/features/profiles/presentation/screens/profiles_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rep_swim/database/daos/profile_dao.dart';

class _NoopProfileDao extends Mock implements ProfileDao {}

class _FixedProfilesNotifier extends ProfilesNotifier {
  _FixedProfilesNotifier(List<SwimmerProfile> profiles)
      : super(_NoopProfileDao()) {
    state = AsyncValue.data(profiles);
  }

  @override
  Future<void> load() async {}
}

Future<void> _pump(
  WidgetTester tester, {
  required List<SwimmerProfile> profiles,
  required List<String> sharedIds,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profilesProvider.overrideWith(
          (ref) => _FixedProfilesNotifier(profiles),
        ),
        profileSummaryProvider.overrideWith(
          (ref, profileId) async => const ProfileSummary(
            sessionCount: 0,
            totalDistance: 0,
            drylandWorkoutCount: 0,
            personalBestCount: 0,
          ),
        ),
        sharedProfileIdsProvider.overrideWith(
          (ref) async => sharedIds,
        ),
      ],
      child: const MaterialApp(home: ProfilesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'shows Shared with coach badge when profile id is in sharedProfileIdsProvider',
    (tester) async {
      await _pump(
        tester,
        profiles: [SwimmerProfile.defaultProfile],
        sharedIds: [kDefaultProfileId],
      );

      expect(find.text('Shared with coach'), findsOneWidget);
    },
  );

  testWidgets(
    'does not show Shared with coach badge when sharedProfileIdsProvider is empty',
    (tester) async {
      await _pump(
        tester,
        profiles: [SwimmerProfile.defaultProfile],
        sharedIds: [],
      );

      expect(find.text('Shared with coach'), findsNothing);
    },
  );
}
