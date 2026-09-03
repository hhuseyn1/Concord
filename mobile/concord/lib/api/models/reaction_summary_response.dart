import 'json_utils.dart';

class ReactionSummaryResponse {
  const ReactionSummaryResponse({required this.emoji, required this.userIds});

  factory ReactionSummaryResponse.fromJson(Map<String, dynamic> json) {
    return ReactionSummaryResponse(
      emoji: json.field('Emoji') as String,
      userIds: parseStringList(json.field('UserIds')),
    );
  }

  final String emoji;
  final List<String> userIds;
}
