import '../entities/swim_session.dart';

abstract class SwimRepository {
  Future<List<SwimSession>> getAllSessions();
  Future<List<SwimSession>> getRecentSessions({int limit = 10});
  Future<void> saveSession(SwimSession session);
  Future<void> deleteSession(String id);
}
