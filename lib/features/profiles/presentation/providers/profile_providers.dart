import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/sync/sync_mode.dart';
import '../../../../core/sync/sync_payloads.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../database/app_database.dart';
import '../../../../database/daos/app_settings_dao.dart';
import '../../../../database/daos/profile_dao.dart';
import '../../../../database/daos/sync_queue_dao.dart';
import '../../domain/entities/swimmer_profile.dart';

const _uuid = Uuid();

final profileDaoProvider = Provider<ProfileDao>((ref) {
  return ProfileDao(AppDatabase.instance);
});

final appSettingsDaoProvider = Provider<AppSettingsDao>((ref) {
  return AppSettingsDao(AppDatabase.instance);
});

class ProfilesNotifier extends StateNotifier<AsyncValue<List<SwimmerProfile>>> {
  ProfilesNotifier(this._dao, {SyncQueueDao? syncQueueDao})
      : _syncQueueDao = syncQueueDao,
        super(const AsyncValue.loading()) {
    load();
  }

  final ProfileDao _dao;
  final SyncQueueDao? _syncQueueDao;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final profiles = await _dao.getAll();
      state = AsyncValue.data(profiles);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<SwimmerProfile> addProfile(String displayName) async {
    return addProfileDetails(displayName: displayName);
  }

  Future<SwimmerProfile> addProfileDetails({
    required String displayName,
    int preferredPoolLengthMeters = 25,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc();
    final profile = SwimmerProfile(
      id: _uuid.v4(),
      displayName: displayName.trim(),
      preferredPoolLengthMeters: preferredPoolLengthMeters,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await _dao.insert(profile);
    await _queueProfile(
      profile,
      operation: SyncOperation.create,
    );
    await load();
    return profile;
  }

  Future<void> updateProfile(SwimmerProfile profile) async {
    final updated = profile.copyWith(
      displayName: profile.displayName.trim(),
      notes:
          profile.notes?.trim().isEmpty == true ? null : profile.notes?.trim(),
      clearNotes: profile.notes?.trim().isEmpty == true,
      updatedAt: DateTime.now().toUtc(),
    );
    await _dao.update(updated);
    await _queueProfile(updated, operation: SyncOperation.update);
    await load();
  }

  Future<void> archiveProfile(String id) async {
    if (id == kDefaultProfileId) return;
    await _dao.archive(id);
    await _queueChange(
      profileId: id,
      entityType: 'swimmer_profile',
      entityId: id,
      operation: SyncOperation.delete,
      payload: deletedEntityPayload(id: id, profileId: id),
    );
    await load();
  }

  Future<void> _queueProfile(
    SwimmerProfile profile, {
    required SyncOperation operation,
  }) async {
    await _queueChange(
      profileId: profile.id,
      entityType: 'swimmer_profile',
      entityId: profile.id,
      operation: operation,
      payload: swimmerProfilePayload(profile),
    );
  }

  Future<void> _queueChange({
    required String profileId,
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, Object?> payload,
  }) async {
    try {
      await _syncQueueDao?.enqueue(
        profileId: profileId,
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: payload,
      );
    } catch (_) {
      // Sync queue failures must not block local-first writes.
    }
  }
}

final profilesProvider =
    StateNotifierProvider<ProfilesNotifier, AsyncValue<List<SwimmerProfile>>>(
  (ref) => ProfilesNotifier(
    ref.read(profileDaoProvider),
    syncQueueDao: ref.read(syncQueueDaoProvider),
  ),
);

final selectedProfileIdProvider = StateProvider<String?>((ref) => null);

final profileSelectionBootstrapProvider = FutureProvider<void>((ref) async {
  final savedProfileId = await ref
      .read(appSettingsDaoProvider)
      .getString(kSelectedProfileIdSetting);
  if (savedProfileId == null || savedProfileId.isEmpty) return;
  ref.read(selectedProfileIdProvider.notifier).state = savedProfileId;
});

final currentProfileIdProvider = Provider<String>((ref) {
  final selected = ref.watch(selectedProfileIdProvider);
  final profiles = ref.watch(profilesProvider).valueOrNull;
  if (selected != null && profiles?.any((p) => p.id == selected) == true) {
    return selected;
  }
  if (profiles != null && profiles.isNotEmpty) {
    return profiles.first.id;
  }
  return kDefaultProfileId;
});

final currentProfileProvider = Provider<SwimmerProfile>((ref) {
  final profileId = ref.watch(currentProfileIdProvider);
  final profiles = ref.watch(profilesProvider).valueOrNull ?? const [];
  return profiles.firstWhere(
    (profile) => profile.id == profileId,
    orElse: () => SwimmerProfile.defaultProfile,
  );
});
