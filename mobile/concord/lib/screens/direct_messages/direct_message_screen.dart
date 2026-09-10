import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../api/models/enums.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/voice_call_controller.dart';
import '../../providers/voice_call_state.dart';
import '../../theme/theme.dart';
import '../../utils/permission_rationale.dart';
import '../../widgets/widgets.dart';
import '../voice/voice_call_controls.dart';
import 'direct_message_view.dart';

Future<void> _startCallWithPermission(
  BuildContext context,
  VoiceCallController controller,
  String conversationId,
  CallType type,
) async {
  final l10n = AppLocalizations.of(context);
  final micGranted = await requestPermissionWithRationale(
    context,
    permission: Permission.microphone,
    title: l10n.microphoneAccessTitle,
    rationale: l10n.microphoneAccessRationale,
  );
  if (!micGranted) return;
  if (type == CallType.video) {
    if (!context.mounted) return;
    final cameraGranted = await requestPermissionWithRationale(
      context,
      permission: Permission.camera,
      title: l10n.cameraAccessTitle,
      rationale: l10n.cameraAccessRationaleVideoCalls,
    );
    if (!cameraGranted) return;
  }
  await controller.startDmCall(conversationId, type);
}

Future<void> _toggleVideoWithPermission(BuildContext context, VoiceCallController controller, bool isVideoEnabled) async {
  if (isVideoEnabled) {
    await controller.toggleVideo();
    return;
  }
  final l10n = AppLocalizations.of(context);
  final granted = await requestPermissionWithRationale(
    context,
    permission: Permission.camera,
    title: l10n.cameraAccessTitle,
    rationale: l10n.cameraAccessRationaleVideoCalls,
  );
  if (granted) await controller.toggleVideo();
}

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
    final l10n = AppLocalizations.of(context);
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
                name ?? l10n.directMessageFallbackTitle,
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
                  tooltip: l10n.startVoiceCallTooltip,
                  onPressed: canStartCall
                      ? () => _startCallWithPermission(context, callController, conversationId, CallType.voice)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.videocam_outlined),
                  tooltip: l10n.startVideoCallTooltip,
                  onPressed: canStartCall
                      ? () => _startCallWithPermission(context, callController, conversationId, CallType.video)
                      : null,
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
                  Expanded(child: Text(l10n.callingEllipsis)),
                  ConcordButton(
                    label: l10n.cancelButton,
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
                    callState.isReconnecting ? l10n.reconnectingEllipsis : l10n.inCallLabel,
                    style: TextStyle(color: callState.isReconnecting ? colors.warning : colors.fgMuted),
                  ),
                  VoiceCallControls(
                    isMuted: callState.isMuted,
                    isDeafened: callState.isDeafened,
                    isVideoEnabled: callState.isVideoEnabled,
                    onToggleMute: callController.toggleMute,
                    onToggleDeafen: callController.toggleDeafen,
                    onToggleVideo: () => _toggleVideoWithPermission(context, callController, callState.isVideoEnabled),
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
