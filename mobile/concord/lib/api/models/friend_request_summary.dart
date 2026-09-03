import 'json_utils.dart';
import 'public_profile_response.dart';

class FriendRequestSummary {
  const FriendRequestSummary({
    required this.id,
    required this.user,
    required this.created,
  });

  factory FriendRequestSummary.fromJson(Map<String, dynamic> json) {
    return FriendRequestSummary(
      id: json.field('Id') as String,
      user: PublicProfileResponse.fromJson(json.field('User') as Map<String, dynamic>),
      created: parseDateTime(json.field('Created')),
    );
  }

  final String id;
  final PublicProfileResponse user;
  final DateTime created;
}
