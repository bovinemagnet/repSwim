import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/core/constants/app_constants.dart';
import 'package:rep_swim/core/sync/sync_mode.dart';
import 'package:rep_swim/database/app_database.dart';
import 'package:rep_swim/database/daos/app_settings_dao.dart';
import 'package:rep_swim/database/daos/profile_dao.dart';
import 'package:rep_swim/database/daos/swim_session_dao.dart';
import 'package:rep_swim/features/profiles/domain/entities/swimmer_profile.dart';
import 'package:rep_swim/features/swim/domain/entities/lap.dart';
import 'package:rep_swim/features/swim/domain/entities/swim_session.dart';

void main() {
  group('app flow integration', () {
    late AppDatabase appDb;

    setUp(() {
      appDb = AppDatabase.test();
    });

    tearDown(() async {
      await appDb.close();
    });

    test('persists selected profile and sync mode settings', () async {
      final settings = AppSettingsDao(appDb);

      await settings.setString(kSelectedProfileIdSetting, 'profile-2');
      await settings.setString(kSyncModeSetting, SyncMode.automatic.name);

      expect(
        await settings.getString(kSelectedProfileIdSetting),
        'profile-2',
      );
      expect(await settings.getString(kSyncModeSetting), 'automatic');
    });

    test('keeps profile-scoped swim sessions isolated', () async {
      final profiles = ProfileDao(appDb);
      final sessions = SwimSessionDao(appDb);
      final now = DateTime.utc(2024, 5, 1);

      await profiles.insert(
        SwimmerProfile(
          id: 'profile-a',
          displayName: 'Ari',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await profiles.insert(
        SwimmerProfile(
          id: 'profile-b',
          displayName: 'Blair',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await sessions.insertSession(_session('session-a', 'profile-a', 50));
      await sessions.insertSession(_session('session-b', 'profile-b', 100));

      final profileASessions = await sessions.getAllSessions('profile-a');
      final profileBSessions = await sessions.getAllSessions('profile-b');

      expect(profileASessions.map((session) => session.id), ['session-a']);
      expect(profileASessions.single.laps.single.profileId, 'profile-a');
      expect(profileBSessions.map((session) => session.id), ['session-b']);
      expect(profileBSessions.single.totalDistance, 100);
    });

    test('archived profiles are hidden but default profile remains available',
        () async {
      final profiles = ProfileDao(appDb);
      final now = DateTime.utc(2024, 5, 1);

      await profiles.insert(
        SwimmerProfile(
          id: 'profile-archive',
          displayName: 'Archive Me',
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(
        (await profiles.getAll()).map((profile) => profile.id),
        contains('profile-archive'),
      );

      await profiles.archive('profile-archive');

      final remaining = await profiles.getAll();
      expect(
        remaining.map((profile) => profile.id),
        isNot(contains('profile-archive')),
      );
      expect(
        remaining.map((profile) => profile.id),
        contains(kDefaultProfileId),
      );
    });
  });
}

SwimSession _session(String id, String profileId, int distance) {
  return SwimSession(
    id: id,
    profileId: profileId,
    date: DateTime.utc(2024, 5, 1),
    totalDistance: distance,
    totalTime: const Duration(seconds: 45),
    stroke: 'Freestyle',
    laps: [
      Lap(
        id: 'lap-$id',
        sessionId: id,
        profileId: profileId,
        distance: distance,
        time: const Duration(seconds: 45),
        lapNumber: 1,
      ),
    ],
  );
}
