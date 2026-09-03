import 'api_client.dart';
import 'models/friend_request_summary.dart';
import 'models/paged_result.dart';
import 'models/public_profile_response.dart';
import 'models/send_request_response.dart';

class FriendsService {
  FriendsService(this._client);

  final ApiClient _client;

  Future<SendRequestResponse> sendRequest(String targetUserId) async {
    final data = await _client.post('/Friends/Requests/$targetUserId');
    return SendRequestResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<void> acceptRequest(String requestId) => _client.post('/Friends/Requests/$requestId:Accept');

  Future<void> declineRequest(String requestId) => _client.post('/Friends/Requests/$requestId:Decline');

  Future<void> cancelRequest(String requestId) => _client.delete('/Friends/Requests/$requestId');

  Future<List<FriendRequestSummary>> incomingRequests() async {
    final data = await _client.get('/Friends/Requests/Incoming');
    return (data as List<dynamic>)
        .map((e) => FriendRequestSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FriendRequestSummary>> outgoingRequests() async {
    final data = await _client.get('/Friends/Requests/Outgoing');
    return (data as List<dynamic>)
        .map((e) => FriendRequestSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PagedResult<PublicProfileResponse>> listFriends({int page = 1, int pageSize = 30}) async {
    final data = await _client.get('/Friends', query: {'page': page, 'pageSize': pageSize});
    return PagedResult.fromJson(data as Map<String, dynamic>, PublicProfileResponse.fromJson);
  }

  Future<void> block(String targetUserId) => _client.post('/Friends/Blocks/$targetUserId');

  Future<void> unblock(String targetUserId) => _client.delete('/Friends/Blocks/$targetUserId');

  Future<PagedResult<PublicProfileResponse>> listBlocked({int page = 1, int pageSize = 30}) async {
    final data = await _client.get('/Friends/Blocks', query: {'page': page, 'pageSize': pageSize});
    return PagedResult.fromJson(data as Map<String, dynamic>, PublicProfileResponse.fromJson);
  }
}
