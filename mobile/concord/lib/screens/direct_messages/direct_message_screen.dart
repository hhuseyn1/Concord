import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/enums.dart';
import '../../providers/voice_call_controller.dart';
import '../../providers/voice_call_state.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../voice/voice_call_controls.dart';
import 'direct_message_view.dart';

class DirectMessageRouteArgs {
  const DirectMessageRouteArgs({this.otherUserName, this.otherUserAvatarUrl});

  final String? otherUserName;
  final String? otherUserAvatarUrl;
}

class DirectMessageScreen extends ConsumerWidget {
  const DirectMessageScreen({super.key, required this.conversationId, this.args});

  final String conversationId;
  final DirectMessageRouteArgs? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final name = args?.otherUserName;
    final callState = ref.watch(voiceCallControllerProvider);
    final callController = ref.read(voiceCallControllerProvider.notifier);

    final isThisCallActive = callState.activeCall?.kind == ActiveCallKind.dm && callState.activeCall?.conversationId == conversationId;
    final isThisCallRinging = callState.outgoingCall?.conversationId == conversationId;
    final canStartCall = callState.outgoingCall == null && callState.incomingCall == null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConcordAvatar(imageUrl: args?.otherUserAvatarUrl, name: name, size: ConcordAvatarSize.sm),
            const SizedBox(width: ConcordSpacing.sm),
            Flexible(
              child: Text(
                name ?? 'Direct Message',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.fgDefault),
              ),
            ),
          ],
        ),
        actions: isThisCallActive || isThisCallRinging
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.call_outlined),
                  tooltip: 'Start voice call',
                  onPressed: canStartCall ? () => callController.startDmCall(conversationId, CallType.voice) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.videocam_outlined),
                  tooltip: 'Start video call',
                  onPressed: canStartCall ? () => callController.startDmCall(conversationId, CallType.video) : null,
                ),
              ],
      ),
      body: Column(
        children: [
          if (isThisCallRinging)
            Container(
              width: double.infinity,
              color: colors.brand.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.sm),
              child: Row(
                children: [
                  const Expanded(child: Text('Calling…')),
                  ConcordButton(
                    label: 'Cancel',
                    variant: ConcordButtonVariant.danger,
                    size: ConcordButtonSize.sm,
                    onPressed: callController.cancelOutgoingCall,
                  ),
                ],
              ),
            ),
          if (isThisCallActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.sm),
              decoration: BoxDecoration(
                color: colors.surfaceSidebar,
                border: Border(bottom: BorderSide(color: colors.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    callState.isReconnecting ? 'Reconnecting…' : 'In call',
                    style: TextStyle(color: callState.isReconnecting ? colors.warning : colors.fgMuted),
                  ),
                  VoiceCallControls(
                    isMuted: callState.isMuted,
                    isDeafened: callState.isDeafened,
                    isVideoEnabled: callState.isVideoEnabled,
                    onToggleMute: callController.toggleMute,
                    onToggleDeafen: callController.toggleDeafen,
                    onToggleVideo: callController.toggleVideo,
                    onLeave: callController.leaveCall,
                  ),
                ],
              ),
            ),
          Expanded(
            child: DirectMessageView(
              key: ValueKey(conversationId),
              conversationId: conversationId,
              otherUserName: name,
              otherUserAvatarUrl: args?.otherUserAvatarUrl,
            ),
          ),
        ],
      ),
    );
  }
}
