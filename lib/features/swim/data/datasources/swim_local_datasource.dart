import '../../../../database/daos/swim_session_dao.dart';
import '../../domain/entities/swim_session.dart';

/// Local data source wrapping the DAO — used by the repository.
class SwimLocalDatasource {
  const SwimLocalDatasource(this._dao);

  final SwimSessionDao _dao;

  Future<List<SwimSession>> fetchAll() => _dao.getAllSessions();

  Future<List<SwimSession>> fetchRecent({int limit = 10}) =>
      _dao.getRecentSessions(limit: limit);

  Future<void> save(SwimSession session) => _dao.insertSession(session);

  Future<void> delete(String id) => _dao.deleteSession(id);
}
