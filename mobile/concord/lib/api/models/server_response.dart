import 'json_utils.dart';

class ServerResponse {
  const ServerResponse({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.iconUrl,
    required this.created,
  });

  factory ServerResponse.fromJson(Map<String, dynamic> json) {
    return ServerResponse(
      id: json.field('Id') as String,
      name: json.field('Name') as String,
      ownerId: json.field('OwnerId') as String,
      iconUrl: json.field('IconUrl') as String?,
      created: parseDateTime(json.field('Created')),
    );
  }

  final String id;
  final String name;
  final String ownerId;
  final String? iconUrl;
  final DateTime created;
}
