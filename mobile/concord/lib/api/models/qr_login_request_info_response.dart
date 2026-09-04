import 'json_utils.dart';

class QrLoginRequestInfoResponse {
  const QrLoginRequestInfoResponse({
    required this.userCode,
    required this.deviceLabel,
    required this.browser,
    required this.os,
    required this.ipAddress,
    required this.requestedAt,
    required this.expiresAtUtc,
  });

  factory QrLoginRequestInfoResponse.fromJson(Map<String, dynamic> json) {
    return QrLoginRequestInfoResponse(
      userCode: json.field('UserCode') as String,
      deviceLabel: json.field('DeviceLabel') as String?,
      browser: json.field('Browser') as String?,
      os: json.field('OS') as String?,
      ipAddress: json.field('IpAddress') as String?,
      requestedAt: parseDateTime(json.field('RequestedAt')),
      expiresAtUtc: parseDateTime(json.field('ExpiresAtUtc')),
    );
  }

  final String userCode;
  final String? deviceLabel;
  final String? browser;
  final String? os;
  final String? ipAddress;
  final DateTime requestedAt;
  final DateTime expiresAtUtc;
}
