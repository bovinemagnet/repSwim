import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/daos/pb_dao.dart';
import '../../domain/entities/personal_best.dart';
import '../../../swim/presentation/providers/swim_providers.dart';
import '../../../profiles/presentation/providers/profile_providers.dart';

class PersonalBestsNotifier
    extends StateNotifier<AsyncValue<List<PersonalBest>>> {
  PersonalBestsNotifier(this._dao, this._profileId)
      : super(const AsyncValue.loading()) {
    load();
  }

  final PbDao _dao;
  final String _profileId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final pbs = await _dao.getAll(_profileId);
      state = AsyncValue.data(pbs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(PersonalBest pb) async {
    await _dao.insertOrUpdate(pb);
    await load();
  }

  Future<void> delete(String id) async {
    await _dao.delete(id, _profileId);
    await load();
  }

  Future<void> replaceAll(List<PersonalBest> pbs) async {
    await _dao.clear(_profileId);
    for (final pb in pbs) {
      await _dao.insertOrUpdate(pb);
    }
    await load();
  }
}

final personalBestsProvider = StateNotifierProvider<PersonalBestsNotifier,
    AsyncValue<List<PersonalBest>>>(
  (ref) => PersonalBestsNotifier(
    ref.read(pbDaoProvider),
    ref.watch(currentProfileIdProvider),
  ),
);
