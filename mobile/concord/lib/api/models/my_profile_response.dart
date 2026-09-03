import 'enums.dart';
import 'json_utils.dart';

class MyProfileResponse {
  const MyProfileResponse({
    required this.id,
    required this.username,
    required this.name,
    required this.surname,
    required this.email,
    required this.phoneNumber,
    required this.avatarUrl,
    required this.locale,
    required this.notificationsMuted,
    required this.notificationsSoundEnabled,
    required this.status,
    required this.customStatusEmoji,
    required this.customStatusText,
    required this.customStatusExpiresAt,
    required this.friendRequestPrivacy,
    required this.directMessagePrivacy,
    required this.activityVisibility,
    required this.readReceiptsEnabled,
    required this.created,
    required this.activityApplicationName,
    required this.activityType,
    required this.activityStartedAt,
  });

  factory MyProfileResponse.fromJson(Map<String, dynamic> json) {
    return MyProfileResponse(
      id: json.field('Id') as String,
      username: json.field('Username') as String?,
      name: json.field('Name') as String?,
      surname: json.field('Surname') as String?,
      email: json.field('Email') as String?,
      phoneNumber: json.field('PhoneNumber') as String?,
      avatarUrl: json.field('AvatarUrl') as String?,
      locale: json.field('Locale') as String?,
      notificationsMuted: json.field('NotificationsMuted') as bool,
      notificationsSoundEnabled: json.field('NotificationsSoundEnabled') as bool,
      status: PresenceStatus.fromWire(json.field('Status')),
      customStatusEmoji: json.field('CustomStatusEmoji') as String?,
      customStatusText: json.field('CustomStatusText') as String?,
      customStatusExpiresAt: parseNullableDateTime(json.field('CustomStatusExpiresAt')),
      friendRequestPrivacy: FriendRequestPrivacy.fromWire(json.field('FriendRequestPrivacy')),
      directMessagePrivacy: DirectMessagePrivacy.fromWire(json.field('DirectMessagePrivacy')),
      activityVisibility: ActivityVisibility.fromWire(json.field('ActivityVisibility')),
      readReceiptsEnabled: json.field('ReadReceiptsEnabled') as bool,
      created: parseDateTime(json.field('Created')),
      activityApplicationName: json.field('ActivityApplicationName') as String?,
      activityType: json.field('ActivityType') == null ? null : ActivityType.fromWire(json.field('ActivityType')),
      activityStartedAt: parseNullableDateTime(json.field('ActivityStartedAt')),
    );
  }

  final String id;
  final String? username;
  final String? name;
  final String? surname;
  final String? email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? locale;
  final bool notificationsMuted;
  final bool notificationsSoundEnabled;
  final PresenceStatus status;
  final String? customStatusEmoji;
  final String? customStatusText;
  final DateTime? customStatusExpiresAt;
  final FriendRequestPrivacy friendRequestPrivacy;
  final DirectMessagePrivacy directMessagePrivacy;
  final ActivityVisibility activityVisibility;
  final bool readReceiptsEnabled;
  final DateTime created;

  final String? activityApplicationName;
  final ActivityType? activityType;
  final DateTime? activityStartedAt;
}
