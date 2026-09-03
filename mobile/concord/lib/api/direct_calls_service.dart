import 'api_client.dart';
import 'models/call_response.dart';
import 'models/enums.dart';
import 'models/paged_result.dart';

class DirectCallsService {
  DirectCallsService(this._client);

  final ApiClient _client;

  Future<CallResponse> startCall(String conversationId, CallType type) async {
    final data = await _client.post(
      '/DirectMessages/Conversations/$conversationId/Calls',
      body: {'Type': type.toWire()},
    );
    return CallResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<CallResponse> acceptCall(String conversationId, String callId) async {
    final data = await _client.post('/DirectMessages/Conversations/$conversationId/Calls/$callId:Accept');
    return CallResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<CallResponse> declineCall(String conversationId, String callId) async {
    final data = await _client.post('/DirectMessages/Conversations/$conversationId/Calls/$callId:Decline');
    return CallResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<CallResponse> endCall(String conversationId, String callId) async {
    final data = await _client.post('/DirectMessages/Conversations/$conversationId/Calls/$callId:End');
    return CallResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<PagedResult<CallResponse>> getCalls(
    String conversationId, {
    required int page,
    required int pageSize,
  }) async {
    final data = await _client.get(
      '/DirectMessages/Conversations/$conversationId/Calls',
      query: {'page': page, 'pageSize': pageSize},
    );
    return PagedResult.fromJson(data as Map<String, dynamic>, CallResponse.fromJson);
  }
}
