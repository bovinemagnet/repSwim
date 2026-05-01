import '../entities/swim_session.dart';

abstract class SwimRepository {
  Future<List<SwimSession>> getAllSessions(String profileId);
  Future<List<SwimSession>> getRecentSessions(String profileId,
      {int limit = 10});
  Future<void> saveSession(SwimSession session);
  Future<void> deleteSession(String id, String profileId);
}
