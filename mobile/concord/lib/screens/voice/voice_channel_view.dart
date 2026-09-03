import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_controller.dart';
import '../../providers/server_providers.dart';
import '../../providers/voice_call_controller.dart';
import '../../providers/voice_call_state.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'participant_tile.dart';
import 'voice_call_controls.dart';

class VoiceChannelView extends ConsumerWidget {
  const VoiceChannelView({super.key, required this.serverId, required this.channelId, this.channelName});

  final String serverId;
  final String channelId;
  final String? channelName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final callState = ref.watch(voiceCallControllerProvider);
    final controller = ref.read(voiceCallControllerProvider.notifier);
    final currentUserId = ref.watch(authControllerProvider).profile?.id;

    final isInThisCall = callState.activeCall?.kind == ActiveCallKind.channel && callState.activeCall?.channelId == channelId;

    if (!isInThisCall) {
      return Center(
        child: ConcordEmptyState(
          icon: Icons.volume_up_outlined,
          title: channelName != null ? 'Join $channelName' : 'Join voice channel',
          subtitle: 'Connect to start talking with everyone in this channel.',
          action: ConcordButton(
            label: callState.isConnecting ? 'Connecting…' : 'Join Voice',
            loading: callState.isConnecting,
            onPressed: callState.isConnecting ? null : () => controller.joinChannelCall(serverId, channelId),
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
              'Reconnecting…',
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
              onToggleVideo: controller.toggleVideo,
              onLeave: controller.leaveCall,
            ),
          ),
        ),
      ],
    );
  }
}
