import 'api_client.dart';
import 'models/session_response.dart';

class SessionsService {
  SessionsService(this._client);

  final ApiClient _client;

  Future<List<SessionResponse>> getMySessions() async {
    final data = await _client.get('/Sessions');
    return (data as List<dynamic>).map((e) => SessionResponse.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> revokeCurrentSession() => _client.delete('/Sessions/Current');

  Future<void> revokeOtherSessions() => _client.delete('/Sessions/Others');

  Future<void> revokeSession(String sessionId) => _client.delete('/Sessions/$sessionId');
}
