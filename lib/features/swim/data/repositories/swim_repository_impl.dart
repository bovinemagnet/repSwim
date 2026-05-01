import '../../../../database/daos/swim_session_dao.dart';
import '../../domain/entities/swim_session.dart';
import '../../domain/repositories/swim_repository.dart';

class SwimRepositoryImpl implements SwimRepository {
  const SwimRepositoryImpl(this._dao);

  final SwimSessionDao _dao;

  @override
  Future<List<SwimSession>> getAllSessions(String profileId) =>
      _dao.getAllSessions(profileId);

  @override
  Future<List<SwimSession>> getRecentSessions(
    String profileId, {
    int limit = 10,
  }) =>
      _dao.getRecentSessions(profileId, limit: limit);

  @override
  Future<void> saveSession(SwimSession session) => _dao.insertSession(session);

  @override
  Future<void> deleteSession(String id, String profileId) =>
      _dao.deleteSession(id, profileId);
}
