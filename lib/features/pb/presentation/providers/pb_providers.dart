import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/daos/pb_dao.dart';
import '../../domain/entities/personal_best.dart';
import '../../../swim/presentation/providers/swim_providers.dart';

class PersonalBestsNotifier
    extends StateNotifier<AsyncValue<List<PersonalBest>>> {
  PersonalBestsNotifier(this._dao) : super(const AsyncValue.loading()) {
    load();
  }

  final PbDao _dao;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final pbs = await _dao.getAll();
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
    await _dao.delete(id);
    await load();
  }
}

final personalBestsProvider = StateNotifierProvider<PersonalBestsNotifier,
    AsyncValue<List<PersonalBest>>>(
  (ref) => PersonalBestsNotifier(ref.read(pbDaoProvider)),
);
