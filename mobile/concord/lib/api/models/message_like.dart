import 'public_profile_response.dart';
import 'reaction_summary_response.dart';

abstract class MessageLike {
  String get id;
  PublicProfileResponse get sender;

  String? get content;
  DateTime get created;
  DateTime? get editedAtUtc;
  String? get attachmentUrl;
  String? get replyToMessageId;
  List<ReactionSummaryResponse> get reactions;
  DateTime? get pinnedAt;
  String? get pinnedByUserId;
  String? get forwardedFromSenderId;
  DateTime? get forwardedFromCreatedAt;
  List<String> get mentionedUserIds;
}
