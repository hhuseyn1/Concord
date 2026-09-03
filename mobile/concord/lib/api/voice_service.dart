import 'api_client.dart';
import 'models/voice_participant_summary.dart';
import 'models/voice_token_response.dart';

class VoiceService {
  VoiceService(this._client);

  final ApiClient _client;

  Future<VoiceTokenResponse> getToken(String channelId) async {
    final data = await _client.post('/Channels/$channelId/Voice/Token');
    return VoiceTokenResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<List<VoiceParticipantSummary>> listParticipants(String channelId) async {
    final data = await _client.get('/Channels/$channelId/Voice/Participants');
    return (data as List<dynamic>)
        .map((e) => VoiceParticipantSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
