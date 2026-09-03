import 'api_client.dart';
import 'models/voice_participant_summary.dart';
import 'models/voice_token_response.dart';

class DirectVoiceService {
  DirectVoiceService(this._client);

  final ApiClient _client;

  Future<VoiceTokenResponse> getToken(String conversationId) async {
    final data = await _client.post('/DirectMessages/Conversations/$conversationId/Voice/Token');
    return VoiceTokenResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<List<VoiceParticipantSummary>> listParticipants(String conversationId) async {
    final data = await _client.get('/DirectMessages/Conversations/$conversationId/Voice/Participants');
    return (data as List<dynamic>)
        .map((e) => VoiceParticipantSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
