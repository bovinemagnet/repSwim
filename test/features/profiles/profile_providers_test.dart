import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rep_swim/core/sync/sync_mode.dart';
import 'package:rep_swim/core/constants/app_constants.dart';
import 'package:rep_swim/database/daos/app_settings_dao.dart';
import 'package:rep_swim/database/daos/profile_dao.dart';
import 'package:rep_swim/database/daos/sync_queue_dao.dart';
import 'package:rep_swim/features/profiles/domain/entities/swimmer_profile.dart';
import 'package:rep_swim/features/profiles/presentation/providers/profile_providers.dart';

class _MockProfileDao extends Mock implements ProfileDao {}

class _MockSyncQueueDao extends Mock implements SyncQueueDao {}

class _MockAppSettingsDao extends Mock implements AppSettingsDao {}

SwimmerProfile _profile({
  String id = 'profile-1',
  String name = 'Ethan',
  int poolLength = 25,
}) {
  return SwimmerProfile(
    id: id,
    displayName: name,
    preferredPoolLengthMeters: poolLength,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_profile());
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(SyncOperation.create);
  });

  group('ProfilesNotifier', () {
    test('addProfileDetails saves and reloads a new swimmer profile', () async {
      final dao = _MockProfileDao();
      final queue = _MockSyncQueueDao();
      when(() => dao.getAll()).thenAnswer((_) async => [_profile()]);
      when(() => dao.insert(any())).thenAnswer((_) async {});
      when(
        () => queue.enqueue(
          profileId: any(named: 'profileId'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          operation: any(named: 'operation'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      final notifier = ProfilesNotifier(dao, syncQueueDao: queue);
      await Future<void>.delayed(Duration.zero);

      final created = await notifier.addProfileDetails(
        displayName: ' Sophie ',
        preferredPoolLengthMeters: 50,
        notes: 'Sprint focus',
      );

      expect(created.displayName, 'Sophie');
      expect(created.preferredPoolLengthMeters, 50);
      expect(created.notes, 'Sprint focus');
      verify(() => dao.insert(any())).called(1);
      verify(
        () => queue.enqueue(
          profileId: created.id,
          entityType: 'swimmer_profile',
          entityId: created.id,
          operation: SyncOperation.create,
          payload: any(named: 'payload'),
        ),
      ).called(1);
      verify(() => dao.getAll()).called(greaterThanOrEqualTo(2));
      expect(notifier.state.valueOrNull?.single.displayName, 'Ethan');
    });

    test('updateProfile trims fields and archives by id', () async {
      final dao = _MockProfileDao();
      final queue = _MockSyncQueueDao();
      final existing = _profile();
      when(() => dao.getAll()).thenAnswer((_) async => [existing]);
      when(() => dao.update(any())).thenAnswer((_) async {});
      when(() => dao.archive(any())).thenAnswer((_) async {});
      when(
        () => queue.enqueue(
          profileId: any(named: 'profileId'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          operation: any(named: 'operation'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      final notifier = ProfilesNotifier(dao, syncQueueDao: queue);
      await Future<void>.delayed(Duration.zero);

      await notifier.updateProfile(
        existing.copyWith(displayName: ' Ethan ', notes: '  '),
      );
      await notifier.archiveProfile(existing.id);

      final captured = verify(() => dao.update(captureAny())).captured.single
          as SwimmerProfile;
      expect(captured.displayName, 'Ethan');
      expect(captured.notes, isNull);
      verify(() => dao.archive(existing.id)).called(1);
      verify(
        () => queue.enqueue(
          profileId: existing.id,
          entityType: 'swimmer_profile',
          entityId: existing.id,
          operation: SyncOperation.update,
          payload: any(named: 'payload'),
        ),
      ).called(1);
      verify(
        () => queue.enqueue(
          profileId: existing.id,
          entityType: 'swimmer_profile',
          entityId: existing.id,
          operation: SyncOperation.delete,
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });
  });

  group('currentProfileIdProvider', () {
    test('falls back when selected profile is archived or missing', () {
      final container = ProviderContainer(
        overrides: [
          profilesProvider.overrideWith(
            (ref) => _StaticProfilesNotifier([_profile(id: 'remaining')]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(selectedProfileIdProvider.notifier).state = 'archived';

      expect(container.read(currentProfileIdProvider), 'remaining');
    });

    test('bootstraps selected profile from persisted app settings', () async {
      final settings = _MockAppSettingsDao();
      when(() => settings.getString(kSelectedProfileIdSetting))
          .thenAnswer((_) async => 'saved-profile');

      final container = ProviderContainer(
        overrides: [
          appSettingsDaoProvider.overrideWithValue(settings),
        ],
      );
      addTearDown(container.dispose);

      await container.read(profileSelectionBootstrapProvider.future);

      expect(container.read(selectedProfileIdProvider), 'saved-profile');
    });
  });
}

class _StaticProfilesNotifier extends ProfilesNotifier {
  _StaticProfilesNotifier(List<SwimmerProfile> profiles)
      : super(_MockProfileDao()) {
    state = AsyncValue.data(profiles);
  }

  @override
  Future<void> load() async {}
}
