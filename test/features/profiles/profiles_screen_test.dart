import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rep_swim/database/daos/profile_dao.dart';
import 'package:rep_swim/features/profiles/domain/entities/swimmer_profile.dart';
import 'package:rep_swim/features/profiles/presentation/providers/profile_providers.dart';
import 'package:rep_swim/features/profiles/presentation/providers/profile_summary_providers.dart';
import 'package:rep_swim/features/profiles/presentation/screens/profiles_screen.dart';

SwimmerProfile _profile() {
  return SwimmerProfile(
    id: 'profile-1',
    displayName: 'Sophie',
    preferredPoolLengthMeters: 50,
    notes: 'Sprint focus',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

SwimmerProfile _currentProfile() {
  return SwimmerProfile(
    id: 'profile-current',
    displayName: 'Ethan',
    preferredPoolLengthMeters: 25,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

void main() {
  testWidgets('shows avatar initial and profile summary stats', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profilesProvider.overrideWith(
            (ref) => _StaticProfilesNotifier([_currentProfile(), _profile()]),
          ),
          profileSummaryProvider.overrideWith(
            (ref, profileId) async => const ProfileSummary(
              sessionCount: 3,
              totalDistance: 750,
              drylandWorkoutCount: 2,
              personalBestCount: 4,
            ),
          ),
        ],
        child: const MaterialApp(home: ProfilesScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Sophie'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(find.text('50m pool · Sprint focus'), findsOneWidget);
    expect(find.text('3 swims · 750m · 2 dryland · 4 PBs'), findsNWidgets(2));
  });
}

class _StaticProfilesNotifier extends ProfilesNotifier {
  _StaticProfilesNotifier(List<SwimmerProfile> profiles)
      : super(_NoopProfileDao()) {
    state = AsyncValue.data(profiles);
  }

  @override
  Future<void> load() async {}
}

class _NoopProfileDao extends Mock implements ProfileDao {}
