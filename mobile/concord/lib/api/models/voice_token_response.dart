import 'json_utils.dart';

class VoiceTokenResponse {
  const VoiceTokenResponse({required this.token, required this.url});

  factory VoiceTokenResponse.fromJson(Map<String, dynamic> json) {
    return VoiceTokenResponse(
      token: json.field('Token') as String,
      url: json.field('Url') as String,
    );
  }

  final String token;
  final String url;
}
