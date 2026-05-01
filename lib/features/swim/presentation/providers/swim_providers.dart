import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/app_database.dart';
import '../../../../database/daos/swim_session_dao.dart';
import '../../../../database/daos/pb_dao.dart';
import '../../../../database/daos/dryland_dao.dart';
import '../../domain/entities/swim_session.dart';
import '../../domain/repositories/swim_repository.dart';
import '../../data/repositories/swim_repository_impl.dart';

// ─── Infrastructure providers ────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final swimSessionDaoProvider = Provider<SwimSessionDao>((ref) {
  return SwimSessionDao(ref.read(databaseProvider));
});

final pbDaoProvider = Provider<PbDao>((ref) {
  return PbDao(ref.read(databaseProvider));
});

final drylandDaoProvider = Provider<DrylandDao>((ref) {
  return DrylandDao(ref.read(databaseProvider));
});

// ─── Repository provider ─────────────────────────────────────────────────────

final swimRepositoryProvider = Provider<SwimRepository>((ref) {
  return SwimRepositoryImpl(ref.read(swimSessionDaoProvider));
});

// ─── Swim sessions notifier ───────────────────────────────────────────────────

class SwimSessionsNotifier extends StateNotifier<AsyncValue<List<SwimSession>>> {
  SwimSessionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final SwimRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final sessions = await _repository.getAllSessions();
      state = AsyncValue.data(sessions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSession(SwimSession session) async {
    await _repository.saveSession(session);
    await load();
  }

  Future<void> deleteSession(String id) async {
    await _repository.deleteSession(id);
    await load();
  }
}

final swimSessionsProvider =
    StateNotifierProvider<SwimSessionsNotifier, AsyncValue<List<SwimSession>>>(
  (ref) => SwimSessionsNotifier(ref.read(swimRepositoryProvider)),
);
