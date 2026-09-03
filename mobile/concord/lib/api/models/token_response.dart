import 'json_utils.dart';

class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpires,
    required this.refreshTokenExpires,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json.field('AccessToken') as String,
      refreshToken: json.field('RefreshToken') as String,
      accessTokenExpires: parseDateTime(json.field('AccessTokenExpires')),
      refreshTokenExpires: parseDateTime(json.field('RefreshTokenExpires')),
    );
  }

  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpires;
  final DateTime refreshTokenExpires;

  Map<String, dynamic> toJson() => {
        'AccessToken': accessToken,
        'RefreshToken': refreshToken,
        'AccessTokenExpires': accessTokenExpires.toIso8601String(),
        'RefreshTokenExpires': refreshTokenExpires.toIso8601String(),
      };
}
