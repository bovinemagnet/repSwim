import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/daos/dryland_dao.dart';
import '../../domain/entities/dryland_workout.dart';
import '../../../swim/presentation/providers/swim_providers.dart';

class DrylandWorkoutsNotifier
    extends StateNotifier<AsyncValue<List<DrylandWorkout>>> {
  DrylandWorkoutsNotifier(this._dao) : super(const AsyncValue.loading()) {
    load();
  }

  final DrylandDao _dao;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final workouts = await _dao.getAll();
      state = AsyncValue.data(workouts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addWorkout(DrylandWorkout workout) async {
    await _dao.insertWorkout(workout);
    await load();
  }

  Future<void> deleteWorkout(String id) async {
    await _dao.deleteWorkout(id);
    await load();
  }
}

final drylandWorkoutsProvider = StateNotifierProvider<DrylandWorkoutsNotifier,
    AsyncValue<List<DrylandWorkout>>>(
  (ref) => DrylandWorkoutsNotifier(ref.read(drylandDaoProvider)),
);
