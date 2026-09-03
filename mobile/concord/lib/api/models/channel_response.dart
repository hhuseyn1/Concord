import 'enums.dart';
import 'json_utils.dart';

class ChannelResponse {
  const ChannelResponse({
    required this.id,
    required this.serverId,
    required this.name,
    required this.type,
    required this.created,
    required this.unreadCount,
  });

  factory ChannelResponse.fromJson(Map<String, dynamic> json) {
    return ChannelResponse(
      id: json.field('Id') as String,
      serverId: json.field('ServerId') as String,
      name: json.field('Name') as String,
      type: ChannelType.fromWire(json.field('Type')),
      created: parseDateTime(json.field('Created')),
      unreadCount: json.field('UnreadCount') as int,
    );
  }

  final String id;
  final String serverId;
  final String name;
  final ChannelType type;
  final DateTime created;

  final int unreadCount;
}
