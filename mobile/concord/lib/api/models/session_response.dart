import 'json_utils.dart';

class SessionResponse {
  const SessionResponse({
    required this.id,
    required this.deviceLabel,
    required this.browser,
    required this.os,
    required this.ipAddress,
    required this.created,
    required this.lastActiveAt,
    required this.isCurrent,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    return SessionResponse(
      id: json.field('Id') as String,
      deviceLabel: json.field('DeviceLabel') as String?,
      browser: json.field('Browser') as String?,
      os: json.field('OS') as String?,
      ipAddress: json.field('IpAddress') as String?,
      created: parseDateTime(json.field('Created')),
      lastActiveAt: parseDateTime(json.field('LastActiveAt')),
      isCurrent: json.field('IsCurrent') as bool,
    );
  }

  final String id;
  final String? deviceLabel;
  final String? browser;
  final String? os;
  final String? ipAddress;
  final DateTime created;
  final DateTime lastActiveAt;
  final bool isCurrent;
}
