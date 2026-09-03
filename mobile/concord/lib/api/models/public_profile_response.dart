import 'enums.dart';
import 'json_utils.dart';

class PublicProfileResponse {
  const PublicProfileResponse({
    required this.id,
    required this.username,
    required this.name,
    required this.surname,
    required this.avatarUrl,
    required this.created,
    required this.status,
    required this.lastSeenAt,
    required this.customStatusEmoji,
    required this.customStatusText,
    required this.relationshipStatus,
    required this.pendingRequestId,
    required this.mutualFriendsCount,
    required this.activityApplicationName,
    required this.activityType,
    required this.activityStartedAt,
  });

  factory PublicProfileResponse.fromJson(Map<String, dynamic> json) {
    return PublicProfileResponse(
      id: json.field('Id') as String,
      username: json.field('Username') as String?,
      name: json.field('Name') as String?,
      surname: json.field('Surname') as String?,
      avatarUrl: json.field('AvatarUrl') as String?,
      created: parseDateTime(json.field('Created')),
      status: PresenceStatus.fromWire(json.field('Status')),
      lastSeenAt: parseNullableDateTime(json.field('LastSeenAt')),
      customStatusEmoji: json.field('CustomStatusEmoji') as String?,
      customStatusText: json.field('CustomStatusText') as String?,
      relationshipStatus: FriendRelationshipStatus.fromWire(json.field('RelationshipStatus')),
      pendingRequestId: json.field('PendingRequestId') as String?,
      mutualFriendsCount: json.field('MutualFriendsCount') as int,
      activityApplicationName: json.field('ActivityApplicationName') as String?,
      activityType: json.field('ActivityType') == null ? null : ActivityType.fromWire(json.field('ActivityType')),
      activityStartedAt: parseNullableDateTime(json.field('ActivityStartedAt')),
    );
  }

  final String id;
  final String? username;
  final String? name;
  final String? surname;
  final String? avatarUrl;
  final DateTime created;
  final PresenceStatus status;
  final DateTime? lastSeenAt;
  final String? customStatusEmoji;
  final String? customStatusText;
  final FriendRelationshipStatus relationshipStatus;
  final String? pendingRequestId;
  final int mutualFriendsCount;
  final String? activityApplicationName;
  final ActivityType? activityType;
  final DateTime? activityStartedAt;

  PublicProfileResponse copyWith({
    String? username,
    String? name,
    String? surname,
    String? avatarUrl,
    PresenceStatus? status,
    DateTime? lastSeenAt,
    bool clearLastSeenAt = false,
    String? customStatusEmoji,
    String? customStatusText,
    FriendRelationshipStatus? relationshipStatus,
    String? pendingRequestId,
    int? mutualFriendsCount,
    String? activityApplicationName,
    ActivityType? activityType,
    DateTime? activityStartedAt,
  }) {
    return PublicProfileResponse(
      id: id,
      username: username ?? this.username,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      created: created,
      status: status ?? this.status,
      lastSeenAt: clearLastSeenAt ? null : (lastSeenAt ?? this.lastSeenAt),
      customStatusEmoji: customStatusEmoji ?? this.customStatusEmoji,
      customStatusText: customStatusText ?? this.customStatusText,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      pendingRequestId: pendingRequestId ?? this.pendingRequestId,
      mutualFriendsCount: mutualFriendsCount ?? this.mutualFriendsCount,
      activityApplicationName: activityApplicationName ?? this.activityApplicationName,
      activityType: activityType ?? this.activityType,
      activityStartedAt: activityStartedAt ?? this.activityStartedAt,
    );
  }
}
