import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rep_swim/core/constants/app_constants.dart';
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
    preferredStrokes: const ['Freestyle', 'Butterfly'],
    primaryEvents: '50m free',
    clubName: 'Metro Swim',
    goals: 'State final',
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

Future<ProviderContainer> _pumpProfiles(
  WidgetTester tester,
  List<SwimmerProfile> profiles,
) async {
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profilesProvider.overrideWith(
          (ref) => _MutableProfilesNotifier(profiles),
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
      child: Builder(
        builder: (context) {
          container = ProviderScope.containerOf(context);
          return const MaterialApp(home: ProfilesScreen());
        },
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets('shows avatar initial and profile summary stats', (tester) async {
    await _pumpProfiles(tester, [_currentProfile(), _profile()]);

    expect(find.text('Sophie'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(
      find.text('50m pool · Metro Swim · Freestyle, Butterfly · 50m free'),
      findsOneWidget,
    );
    expect(find.text('Goals: State final'), findsOneWidget);
    expect(find.text('Sprint focus'), findsOneWidget);
    expect(find.text('3 swims · 750m · 2 dryland · 4 PBs'), findsNWidgets(2));
  });

  testWidgets('adds swimmer from the form dialog and selects it',
      (tester) async {
    final container = await _pumpProfiles(tester, [_currentProfile()]);

    await tester.tap(find.text('Add Swimmer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Mia');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Pool length (m)'),
      '33',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Photo path or URL'),
      '/tmp/mia-profile.jpg',
    );
    await tester.tap(find.widgetWithText(FilterChip, 'Freestyle'));
    await tester.tap(find.widgetWithText(FilterChip, 'Backstroke'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Primary events'),
      '200m back',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Club or team'),
      'Harbour Swim',
    );
    await tester.ensureVisible(find.widgetWithText(TextFormField, 'Goals'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Goals'),
      'Qualify for states',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Notes'),
      'Open water',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Mia'), findsOneWidget);
    expect(
      find.text('33m pool · Harbour Swim · Freestyle, Backstroke · 200m back'),
      findsOneWidget,
    );
    expect(find.text('Goals: Qualify for states'), findsOneWidget);
    expect(find.text('Open water'), findsOneWidget);
    expect(container.read(selectedProfileIdProvider), 'created-1');
  });

  testWidgets('validates profile form fields', (tester) async {
    await _pumpProfiles(tester, [_currentProfile()]);

    await tester.tap(find.text('Add Swimmer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pump();

    expect(find.text('Required'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Pool length (m)'),
      '0',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pump();

    expect(find.text('Enter a pool length'), findsOneWidget);
  });

  testWidgets('archives selected swimmer and falls back to remaining profile',
      (tester) async {
    final current = _currentProfile();
    final container = await _pumpProfiles(tester, [current, _profile()]);
    container.read(selectedProfileIdProvider.notifier).state = current.id;
    await tester.pump();

    final archiveButtons = find.byTooltip('Archive swimmer');
    await tester.tap(archiveButtons.first);
    await tester.pumpAndSettle();
    expect(find.text('Archive swimmer?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
    await tester.pumpAndSettle();

    expect(find.text('Ethan'), findsNothing);
    expect(find.text('Sophie'), findsOneWidget);
    expect(container.read(selectedProfileIdProvider), 'profile-1');
    expect(find.text('Swimmer archived.'), findsOneWidget);
  });

  testWidgets('does not archive the default profile', (tester) async {
    await _pumpProfiles(tester, [
      SwimmerProfile.defaultProfile,
      _profile(),
    ]);

    await tester.tap(find.byTooltip('Archive swimmer').first);
    await tester.pump();

    expect(
      find.text('At least one swimmer profile is required.'),
      findsOneWidget,
    );
    expect(find.text(kDefaultProfileName), findsOneWidget);
  });
}

class _MutableProfilesNotifier extends ProfilesNotifier {
  _MutableProfilesNotifier(List<SwimmerProfile> profiles)
      : _profiles = [...profiles],
        super(_NoopProfileDao()) {
    state = AsyncValue.data(_profiles);
  }

  final List<SwimmerProfile> _profiles;
  int _createdCount = 0;

  @override
  Future<void> load() async {
    state = AsyncValue.data([..._profiles]);
  }

  @override
  Future<SwimmerProfile> addProfileDetails({
    required String displayName,
    int preferredPoolLengthMeters = 25,
    String? photoUri,
    List<String> preferredStrokes = const [],
    String? primaryEvents,
    String? clubName,
    String? goals,
    String? notes,
  }) async {
    final now = DateTime(2024);
    final profile = SwimmerProfile(
      id: 'created-${++_createdCount}',
      displayName: displayName.trim(),
      preferredPoolLengthMeters: preferredPoolLengthMeters,
      photoUri: photoUri?.trim().isEmpty == true ? null : photoUri?.trim(),
      preferredStrokes: preferredStrokes,
      primaryEvents:
          primaryEvents?.trim().isEmpty == true ? null : primaryEvents?.trim(),
      clubName: clubName?.trim().isEmpty == true ? null : clubName?.trim(),
      goals: goals?.trim().isEmpty == true ? null : goals?.trim(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      createdAt: now,
      updatedAt: now,
    );
    _profiles.add(profile);
    await load();
    return profile;
  }

  @override
  Future<void> updateProfile(SwimmerProfile profile) async {
    final index = _profiles.indexWhere((item) => item.id == profile.id);
    if (index >= 0) {
      _profiles[index] = profile;
    }
    await load();
  }

  @override
  Future<void> archiveProfile(String id) async {
    if (id == kDefaultProfileId) return;
    _profiles.removeWhere((profile) => profile.id == id);
    await load();
  }
}

class _NoopProfileDao extends Mock implements ProfileDao {}
