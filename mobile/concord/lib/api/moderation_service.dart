import 'api_client.dart';
import 'models/member_moderation_response.dart';

/// Ban, mute, and timeout (P1) — mirrors `ModerationController`
/// (`Api/V1.0/Servers/{serverId}`). Kick is *not* here: it stays on
/// `ServersService.kickMember` (`DELETE Servers/{id}/Members/{userId}`), matching how the web
/// app's `moderationService.js` also leaves kick on `serversService`.
class ModerationService {
  ModerationService(this._client);

  final ApiClient _client;

  Future<MemberModerationResponse> getMemberModeration(String serverId, String userId) async {
    final data = await _client.get('/Servers/$serverId/Members/$userId/Moderation');
    return MemberModerationResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<MemberModerationResponse> muteMember(String serverId, String userId) async {
    final data = await _client.put('/Servers/$serverId/Members/$userId/Mute');
    return MemberModerationResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<MemberModerationResponse> unmuteMember(String serverId, String userId) async {
    final data = await _client.delete('/Servers/$serverId/Members/$userId/Mute');
    return MemberModerationResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<MemberModerationResponse> timeoutMember(
    String serverId,
    String userId, {
    required int durationMinutes,
    String? reason,
  }) async {
    final data = await _client.put(
      '/Servers/$serverId/Members/$userId/Timeout',
      body: {'DurationMinutes': durationMinutes, 'Reason': reason},
    );
    return MemberModerationResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<MemberModerationResponse> removeTimeout(String serverId, String userId) async {
    final data = await _client.delete('/Servers/$serverId/Members/$userId/Timeout');
    return MemberModerationResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<void> banMember(String serverId, String userId, {String? reason, DateTime? expiresAtUtc}) {
    return _client.put(
      '/Servers/$serverId/Bans/$userId',
      body: {'Reason': reason, 'ExpiresAtUtc': expiresAtUtc?.toIso8601String()},
    );
  }
}
