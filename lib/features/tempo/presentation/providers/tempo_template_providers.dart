import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/sync/sync_mode.dart';
import '../../../../core/sync/sync_payloads.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../database/daos/sync_queue_dao.dart';
import '../../../../database/daos/training_template_dao.dart';
import '../../../profiles/presentation/providers/profile_providers.dart';
import '../../../templates/presentation/providers/training_template_providers.dart';
import '../../domain/entities/tempo_session_result.dart';
import '../../domain/entities/tempo_template.dart';
import 'tempo_trainer_provider.dart';

const _uuid = Uuid();

class TempoTemplatesNotifier
    extends StateNotifier<AsyncValue<List<TempoTemplate>>> {
  TempoTemplatesNotifier(
    this._dao,
    this._profileId, {
    SyncQueueDao? syncQueueDao,
    void Function(Object error)? onQueueFailure,
  })  : _syncQueueDao = syncQueueDao,
        _onQueueFailure = onQueueFailure,
        super(const AsyncValue.loading()) {
    load();
  }

  final TrainingTemplateDao _dao;
  final String _profileId;
  final SyncQueueDao? _syncQueueDao;
  final void Function(Object error)? _onQueueFailure;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final templates = await _dao.getTempoTemplates(_profileId);
      state = AsyncValue.data(templates);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<TempoTemplate> saveFromState(
    String name,
    TempoTrainerState trainer,
  ) async {
    final now = DateTime.now().toUtc();
    final template = trainer.toTemplate(
      id: _uuid.v4(),
      profileId: _profileId,
      name: name.trim(),
      now: now,
    );
    await _dao.insertTempoTemplate(template);
    await _queueChange(
      entityType: 'tempo_template',
      entityId: template.id,
      operation: SyncOperation.create,
      payload: tempoTemplatePayload(template),
    );
    await load();
    return template;
  }

  Future<void> deleteTemplate(String id) async {
    await _dao.deleteTempoTemplate(id, _profileId);
    await _queueChange(
      entityType: 'tempo_template',
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
    } catch (error) {
      _onQueueFailure?.call(error);
    }
  }
}

final tempoTemplatesProvider = StateNotifierProvider.autoDispose<
    TempoTemplatesNotifier, AsyncValue<List<TempoTemplate>>>(
  (ref) => TempoTemplatesNotifier(
    ref.read(trainingTemplateDaoProvider),
    ref.watch(currentProfileIdProvider),
    syncQueueDao: ref.read(syncQueueDaoProvider),
    onQueueFailure: (error) {
      ref.read(syncQueueFailureProvider.notifier).state = error.toString();
    },
  ),
);

class TempoSessionResultsNotifier
    extends StateNotifier<AsyncValue<List<TempoSessionResult>>> {
  TempoSessionResultsNotifier(
    this._dao,
    this._profileId, {
    SyncQueueDao? syncQueueDao,
    void Function(Object error)? onQueueFailure,
  })  : _syncQueueDao = syncQueueDao,
        _onQueueFailure = onQueueFailure,
        super(const AsyncValue.loading()) {
    load();
  }

  final TrainingTemplateDao _dao;
  final String _profileId;
  final SyncQueueDao? _syncQueueDao;
  final void Function(Object error)? _onQueueFailure;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final results = await _dao.getTempoSessionResults(_profileId);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<TempoSessionResult> saveResult({
    required TempoTrainerState trainer,
    String? templateId,
    required List<Duration> actualSplits,
    required List<int> strokeCounts,
    int? rpe,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc();
    final result = TempoSessionResult(
      id: _uuid.v4(),
      profileId: _profileId,
      templateId: templateId,
      mode: trainer.mode,
      startedAt: now,
      completedAt: now,
      targetDistanceMeters: trainer.targetDistanceMeters,
      poolLengthMeters: trainer.poolLengthMeters,
      targetTime: trainer.targetTime,
      targetStrokeRate: trainer.strokeRate,
      actualSplits: actualSplits,
      strokeCounts: strokeCounts,
      rpe: rpe,
      notes: (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
    );
    await _dao.insertTempoSessionResult(result);
    await _queueChange(
      entityType: 'tempo_session_result',
      entityId: result.id,
      operation: SyncOperation.create,
      payload: tempoSessionResultPayload(result),
    );
    await load();
    return result;
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
    } catch (error) {
      _onQueueFailure?.call(error);
    }
  }
}

final tempoSessionResultsProvider = StateNotifierProvider.autoDispose<
    TempoSessionResultsNotifier, AsyncValue<List<TempoSessionResult>>>(
  (ref) => TempoSessionResultsNotifier(
    ref.read(trainingTemplateDaoProvider),
    ref.watch(currentProfileIdProvider),
    syncQueueDao: ref.read(syncQueueDaoProvider),
    onQueueFailure: (error) {
      ref.read(syncQueueFailureProvider.notifier).state = error.toString();
    },
  ),
);
