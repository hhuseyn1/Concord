import 'api_client.dart';
import 'models/invite_response.dart';
import 'models/paged_result.dart';
import 'models/server_member_summary.dart';
import 'models/server_response.dart';

class ServersService {
  ServersService(this._client);

  final ApiClient _client;

  Future<ServerResponse> createServer({required String name, String? iconUrl}) async {
    final data = await _client.post('/Servers', body: {'Name': name, 'IconUrl': iconUrl});
    return ServerResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ServerResponse>> listServers() async {
    final data = await _client.get('/Servers');
    return (data as List<dynamic>)
        .map((e) => ServerResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ServerResponse> joinServer(String inviteCode) async {
    final data = await _client.post('/Servers/Join/$inviteCode');
    return ServerResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<void> leaveServer(String serverId) => _client.delete('/Servers/$serverId/Members/Me');

  Future<void> kickMember(String serverId, String userId) =>
      _client.delete('/Servers/$serverId/Members/$userId');

  Future<void> transferOwnership({required String serverId, required String newOwnerUserId}) {
    return _client.post(
      '/Servers/$serverId/Ownership/Transfer',
      body: {'NewOwnerUserId': newOwnerUserId},
    );
  }

  Future<PagedResult<ServerMemberSummary>> listMembers(
    String serverId, {
    int page = 1,
    int pageSize = 30,
  }) async {
    final data = await _client.get(
      '/Servers/$serverId/Members',
      query: {'page': page, 'pageSize': pageSize},
    );
    return PagedResult.fromJson(data as Map<String, dynamic>, ServerMemberSummary.fromJson);
  }

  Future<InviteResponse> createInvite(
    String serverId, {
    DateTime? expiresAtUtc,
    int? maxUses,
  }) async {
    final data = await _client.post(
      '/Servers/$serverId/Invites',
      body: {'ExpiresAtUtc': expiresAtUtc?.toIso8601String(), 'MaxUses': maxUses},
    );
    return InviteResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<List<InviteResponse>> listInvites(String serverId) async {
    final data = await _client.get('/Servers/$serverId/Invites');
    return (data as List<dynamic>).map((e) => InviteResponse.fromJson(e as Map<String, dynamic>)).toList();
  }
}
