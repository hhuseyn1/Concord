import 'json_utils.dart';
import 'public_profile_response.dart';

class ServerMemberSummary {
  const ServerMemberSummary({
    required this.user,
    required this.joinedAt,
    required this.isMuted,
    required this.timedOutUntil,
  });

  factory ServerMemberSummary.fromJson(Map<String, dynamic> json) {
    return ServerMemberSummary(
      user: PublicProfileResponse.fromJson(json.field('User') as Map<String, dynamic>),
      joinedAt: parseDateTime(json.field('JoinedAt')),
      isMuted: json.field('IsMuted') as bool? ?? false,
      timedOutUntil: parseNullableDateTime(json.field('TimedOutUntil')),
    );
  }

  final PublicProfileResponse user;
  final DateTime joinedAt;

  final bool isMuted;

  final DateTime? timedOutUntil;

  bool get isTimedOut => timedOutUntil != null && timedOutUntil!.isAfter(DateTime.now());

  ServerMemberSummary copyWith({
    PublicProfileResponse? user,
    bool? isMuted,
    DateTime? timedOutUntil,
    bool clearTimedOutUntil = false,
  }) {
    return ServerMemberSummary(
      user: user ?? this.user,
      joinedAt: joinedAt,
      isMuted: isMuted ?? this.isMuted,
      timedOutUntil: clearTimedOutUntil ? null : (timedOutUntil ?? this.timedOutUntil),
    );
  }
}
