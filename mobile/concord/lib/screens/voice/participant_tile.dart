import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class ParticipantTile extends StatelessWidget {
  const ParticipantTile({
    super.key,
    required this.userId,
    required this.isLocal,
    required this.isSpeaking,
    this.room,
    this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final bool isLocal;
  final bool isSpeaking;
  final lk.Room? room;
  final String? displayName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final lkParticipant = room?.getParticipantByIdentity(userId);

    final isMuted = lkParticipant?.isMuted ?? false;
    final videoTrack = _firstVideoTrack(lkParticipant?.videoTrackPublications);

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRail,
        borderRadius: BorderRadius.circular(ConcordRadii.md),
        border: Border.all(color: isSpeaking ? colors.brand : colors.borderSubtle, width: isSpeaking ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (videoTrack != null)
            lk.VideoTrackRenderer(videoTrack, mirrorMode: isLocal ? lk.VideoViewMirrorMode.mirror : lk.VideoViewMirrorMode.off)
          else
            Center(
              child: ConcordAvatar(imageUrl: avatarUrl, name: displayName ?? userId, size: ConcordAvatarSize.lg),
            ),
          Positioned(
            left: ConcordSpacing.sm,
            bottom: ConcordSpacing.sm,
            right: ConcordSpacing.sm,
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(ConcordRadii.sm),
                    ),
                    child: Text(
                      isLocal ? l10n.participantYouSuffix(displayName ?? l10n.youFallback) : (displayName ?? l10n.memberFallback),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                if (isMuted) ...[
                  const SizedBox(width: ConcordSpacing.xs),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.mic_off, size: 12, color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

lk.VideoTrack? _firstVideoTrack(Iterable<dynamic>? publications) {
  if (publications == null) return null;
  for (final publication in publications) {
    final track = publication.track;
    if (track is lk.VideoTrack) return track;
  }
  return null;
}
