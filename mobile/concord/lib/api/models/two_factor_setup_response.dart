import 'json_utils.dart';

class TwoFactorSetupResponse {
  const TwoFactorSetupResponse({required this.secretKey, required this.otpAuthUri, required this.qrCodeSvg});

  factory TwoFactorSetupResponse.fromJson(Map<String, dynamic> json) {
    return TwoFactorSetupResponse(
      secretKey: json.field('SecretKey') as String?,
      otpAuthUri: json.field('OtpAuthUri') as String?,
      qrCodeSvg: json.field('QrCodeSvg') as String?,
    );
  }

  final String? secretKey;

  final String? otpAuthUri;

  final String? qrCodeSvg;
}
