import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_controller.dart';
import '../../providers/server_providers.dart';
import '../../providers/voice_call_controller.dart';
import '../../providers/voice_call_state.dart';
import '../../theme/theme.dart';
import '../../utils/permission_rationale.dart';
import '../../widgets/widgets.dart';
import 'participant_tile.dart';
import 'voice_call_controls.dart';

Future<void> _joinChannelCallWithPermission(BuildContext context, VoiceCallController controller, String serverId, String channelId) async {
  final l10n = AppLocalizations.of(context);
  final granted = await requestPermissionWithRationale(
    context,
    permission: Permission.microphone,
    title: l10n.microphoneAccessTitle,
    rationale: l10n.microphoneAccessRationaleChannel,
  );
  if (granted) await controller.joinChannelCall(serverId, channelId);
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

class VoiceChannelView extends ConsumerWidget {
  const VoiceChannelView({super.key, required this.serverId, required this.channelId, this.channelName});

  final String serverId;
  final String channelId;
  final String? channelName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);
    final callState = ref.watch(voiceCallControllerProvider);
    final controller = ref.read(voiceCallControllerProvider.notifier);
    final currentUserId = ref.watch(authControllerProvider).profile?.id;

    final isInThisCall = callState.activeCall?.kind == ActiveCallKind.channel && callState.activeCall?.channelId == channelId;

    if (!isInThisCall) {
      return Center(
        child: ConcordEmptyState(
          icon: Icons.volume_up_outlined,
          title: channelName != null ? l10n.joinChannelTitle(channelName!) : l10n.joinVoiceChannelTitle,
          subtitle: l10n.joinVoiceChannelSubtitle,
          action: ConcordButton(
            label: callState.isConnecting ? l10n.connectingEllipsis : l10n.joinVoiceButton,
            loading: callState.isConnecting,
            onPressed: callState.isConnecting ? null : () => _joinChannelCallWithPermission(context, controller, serverId, channelId),
          ),
        ),
      );
    }

    final membersAsync = ref.watch(serverMembersProvider(serverId));
    final memberById = {
      for (final member in membersAsync.asData?.value ?? const [])
        member.user.id: member.user,
    };

    final tileIds = {...callState.participants.keys, ?currentUserId}.toList();

    return Column(
      children: [
        if (callState.isReconnecting)
          Container(
            width: double.infinity,
            color: colors.warning.withValues(alpha: 0.15),
            padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
            child: Text(
              l10n.reconnectingEllipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.warning, fontWeight: FontWeight.w500),
            ),
          ),
        Expanded(
          child: tileIds.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(ConcordSpacing.md),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: ConcordSpacing.md,
                    crossAxisSpacing: ConcordSpacing.md,
                    childAspectRatio: 1,
                  ),
                  itemCount: tileIds.length,
                  itemBuilder: (context, index) {
                    final userId = tileIds[index];
                    final member = memberById[userId];
                    return ParticipantTile(
                      userId: userId,
                      isLocal: userId == currentUserId,
                      isSpeaking: callState.activeSpeakerIds.contains(userId),
                      room: callState.room,
                      displayName: member?.username?.isNotEmpty == true
                          ? member!.username
                          : [member?.name, member?.surname].where((p) => p != null && p.isNotEmpty).join(' '),
                      avatarUrl: member?.avatarUrl,
                    );
                  },
                ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.md),
          decoration: BoxDecoration(color: colors.surfaceSidebar, border: Border(top: BorderSide(color: colors.borderSubtle))),
          child: Center(
            child: VoiceCallControls(
              isMuted: callState.isMuted,
              isDeafened: callState.isDeafened,
              isVideoEnabled: callState.isVideoEnabled,
              onToggleMute: controller.toggleMute,
              onToggleDeafen: controller.toggleDeafen,
              onToggleVideo: () => _toggleVideoWithPermission(context, controller, callState.isVideoEnabled),
              onLeave: controller.leaveCall,
            ),
          ),
        ),
      ],
    );
  }
}
