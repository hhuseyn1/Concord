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

  /// Base32 secret, space-grouped for readable manual entry when a QR cannot be scanned.
  final String? secretKey;

  /// Standard `otpauth://totp/...` URI - what the QR encodes.
  final String? otpAuthUri;

  /// The same URI rendered as an SVG data URI (`data:image/svg+xml;base64,...`), ready to display directly.
  final String? qrCodeSvg;
}
