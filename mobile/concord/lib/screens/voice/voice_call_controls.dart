import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class VoiceCallControls extends StatelessWidget {
  const VoiceCallControls({
    super.key,
    required this.isMuted,
    required this.isDeafened,
    required this.isVideoEnabled,
    required this.onToggleMute,
    required this.onToggleDeafen,
    required this.onToggleVideo,
    required this.onLeave,
  });

  final bool isMuted;
  final bool isDeafened;
  final bool isVideoEnabled;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleDeafen;
  final VoidCallback onToggleVideo;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConcordIconButton(
          icon: isMuted ? Icons.mic_off : Icons.mic,
          tooltip: isMuted ? 'Unmute microphone' : 'Mute microphone',
          variant: isMuted ? ConcordButtonVariant.danger : ConcordButtonVariant.secondary,
          onPressed: onToggleMute,
        ),
        const SizedBox(width: ConcordSpacing.sm),
        ConcordIconButton(
          icon: isDeafened ? Icons.headset_off : Icons.headset,
          tooltip: isDeafened ? 'Undeafen' : 'Deafen',
          variant: isDeafened ? ConcordButtonVariant.danger : ConcordButtonVariant.secondary,
          onPressed: onToggleDeafen,
        ),
        const SizedBox(width: ConcordSpacing.sm),
        ConcordIconButton(
          icon: isVideoEnabled ? Icons.videocam : Icons.videocam_off,
          tooltip: isVideoEnabled ? 'Turn off camera' : 'Turn on camera',
          variant: isVideoEnabled ? ConcordButtonVariant.primary : ConcordButtonVariant.secondary,
          onPressed: onToggleVideo,
        ),
        const SizedBox(width: ConcordSpacing.sm),
        ConcordIconButton(
          icon: Icons.call_end,
          tooltip: 'Leave call',
          variant: ConcordButtonVariant.danger,
          onPressed: onLeave,
        ),
      ],
    );
  }
}
