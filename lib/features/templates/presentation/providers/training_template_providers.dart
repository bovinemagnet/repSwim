import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/sync/sync_mode.dart';
import '../../../../core/sync/sync_payloads.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../database/app_database.dart';
import '../../../../database/daos/sync_queue_dao.dart';
import '../../../../database/daos/training_template_dao.dart';
import '../../../dryland/domain/entities/dryland_workout.dart';
import '../../../profiles/presentation/providers/profile_providers.dart';
import '../../../stopwatch/presentation/providers/interval_timer_provider.dart';
import '../../domain/entities/dryland_routine_template.dart';
import '../../domain/entities/interval_template.dart';

const _uuid = Uuid();

final trainingTemplateDaoProvider = Provider<TrainingTemplateDao>((ref) {
  return TrainingTemplateDao(AppDatabase.instance);
});

class IntervalTemplatesNotifier
    extends StateNotifier<AsyncValue<List<IntervalTemplate>>> {
  IntervalTemplatesNotifier(
    this._dao,
    this._profileId, {
    SyncQueueDao? syncQueueDao,
  })  : _syncQueueDao = syncQueueDao,
        super(const AsyncValue.loading()) {
    load();
  }

  final TrainingTemplateDao _dao;
  final String _profileId;
  final SyncQueueDao? _syncQueueDao;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final templates = await _dao.getIntervalTemplates(_profileId);
      state = AsyncValue.data(templates);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<IntervalTemplate> saveFromState(
    String name,
    IntervalTimerState timer,
  ) async {
    final now = DateTime.now().toUtc();
    final template = IntervalTemplate(
      id: _uuid.v4(),
      profileId: _profileId,
      name: name.trim(),
      sets: timer.sets,
      reps: timer.reps,
      workDuration: timer.workDuration,
      restDuration: timer.restDuration,
      createdAt: now,
      updatedAt: now,
    );
    await _dao.insertIntervalTemplate(template);
    await _queueChange(
      entityType: 'interval_template',
      entityId: template.id,
      operation: SyncOperation.create,
      payload: intervalTemplatePayload(template),
    );
    await load();
    return template;
  }

  Future<void> deleteTemplate(String id) async {
    await _dao.deleteIntervalTemplate(id, _profileId);
    await _queueChange(
      entityType: 'interval_template',
      entityId: id,
      operation: SyncOperation.delete,
      payload: deletedEntityPayload(id: id, profileId: _profileId),
    );
    await load();
  }

  Future<void> _queueChange({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, Object?> payload,
  }) async {
    try {
      await _syncQueueDao?.enqueue(
        profileId: _profileId,
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

final intervalTemplatesProvider = StateNotifierProvider.autoDispose<
    IntervalTemplatesNotifier, AsyncValue<List<IntervalTemplate>>>(
  (ref) => IntervalTemplatesNotifier(
    ref.read(trainingTemplateDaoProvider),
    ref.watch(currentProfileIdProvider),
    syncQueueDao: ref.read(syncQueueDaoProvider),
  ),
);

class DrylandRoutineTemplatesNotifier
    extends StateNotifier<AsyncValue<List<DrylandRoutineTemplate>>> {
  DrylandRoutineTemplatesNotifier(
    this._dao,
    this._profileId, {
    SyncQueueDao? syncQueueDao,
  })  : _syncQueueDao = syncQueueDao,
        super(const AsyncValue.loading()) {
    load();
  }

  final TrainingTemplateDao _dao;
  final String _profileId;
  final SyncQueueDao? _syncQueueDao;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final templates = await _dao.getDrylandRoutineTemplates(_profileId);
      state = AsyncValue.data(templates);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<DrylandRoutineTemplate> saveFromWorkout(
    String name,
    DrylandWorkout workout,
  ) async {
    final now = DateTime.now().toUtc();
    final templateId = _uuid.v4();
    final template = DrylandRoutineTemplate(
      id: templateId,
      profileId: _profileId,
      name: name.trim(),
      notes: workout.notes,
      createdAt: now,
      updatedAt: now,
      exercises: [
        for (final exercise in workout.exercises)
          DrylandRoutineExerciseTemplate(
            id: _uuid.v4(),
            templateId: templateId,
            profileId: _profileId,
            name: exercise.name,
            sets: exercise.sets,
            reps: exercise.reps,
            weight: exercise.weight,
          ),
      ],
    );
    await _dao.insertDrylandRoutineTemplate(template);
    await _queueChange(
      entityType: 'dryland_routine_template',
      entityId: template.id,
      operation: SyncOperation.create,
      payload: drylandRoutineTemplatePayload(template),
    );
    await load();
    return template;
  }

  Future<void> deleteTemplate(String id) async {
    await _dao.deleteDrylandRoutineTemplate(id, _profileId);
    await _queueChange(
      entityType: 'dryland_routine_template',
      entityId: id,
      operation: SyncOperation.delete,
      payload: deletedEntityPayload(id: id, profileId: _profileId),
    );
    await load();
  }

  Future<void> _queueChange({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, Object?> payload,
  }) async {
    try {
      await _syncQueueDao?.enqueue(
        profileId: _profileId,
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

final drylandRoutineTemplatesProvider = StateNotifierProvider.autoDispose<
    DrylandRoutineTemplatesNotifier, AsyncValue<List<DrylandRoutineTemplate>>>(
  (ref) => DrylandRoutineTemplatesNotifier(
    ref.read(trainingTemplateDaoProvider),
    ref.watch(currentProfileIdProvider),
    syncQueueDao: ref.read(syncQueueDaoProvider),
  ),
);
