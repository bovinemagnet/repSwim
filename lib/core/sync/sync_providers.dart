import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../../database/app_database.dart';
import '../../database/daos/sync_queue_dao.dart';
import '../../features/profiles/presentation/providers/profile_providers.dart';
import 'sync_mode.dart';
import 'sync_service.dart';

final syncModeProvider = StateProvider<SyncMode>((ref) => SyncMode.localOnly);

final syncModeBootstrapProvider = FutureProvider<void>((ref) async {
  final saved =
      await ref.read(appSettingsDaoProvider).getString(kSyncModeSetting);
  if (saved == null || saved.isEmpty) return;
  for (final mode in SyncMode.values) {
    if (mode.name != saved) continue;
    ref.read(syncModeProvider.notifier).state = mode;
    return;
  }
});

final syncQueueFailureProvider = StateProvider<String?>((ref) => null);

Future<void> setSyncMode(WidgetRef ref, SyncMode mode) async {
  ref.read(syncModeProvider.notifier).state = mode;
  await ref.read(appSettingsDaoProvider).setString(kSyncModeSetting, mode.name);
}

final syncQueueDaoProvider = Provider<SyncQueueDao>((ref) {
  return SyncQueueDao(AppDatabase.instance);
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    mode: ref.watch(syncModeProvider),
    queueDao: ref.read(syncQueueDaoProvider),
  );
});

final syncQueueSummaryProvider =
    FutureProvider.autoDispose<SyncQueueSummary>((ref) {
  final profileId = ref.watch(currentProfileIdProvider);
  return ref.read(syncQueueDaoProvider).getSummary(profileId: profileId);
});
