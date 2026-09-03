import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../providers/auth_controller.dart';
import '../../providers/server_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'member_moderation_sheet.dart';

class ServerMemberRow extends ConsumerWidget {
  const ServerMemberRow({super.key, required this.serverId, required this.member});

  final String serverId;
  final ServerMemberSummary member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final displayName = displayNameFor(member.user);

    final currentUserId = ref.watch(authControllerProvider).profile?.id;
    final permissionsAsync = ref.watch(myPermissionsProvider(serverId));
    final permissions = permissionsAsync.maybeWhen(data: (p) => p, orElse: () => null);

    final isSelf = member.user.id == currentUserId;
    final serverOwnerId = ref.watch(myServersProvider).maybeWhen(
          data: (servers) => servers.where((s) => s.id == serverId).firstOrNull?.ownerId,
          orElse: () => null,
        );
    final isTargetOwner = serverOwnerId != null && serverOwnerId == member.user.id;
    final canModerate = permissions != null && permissions.hasAnyModerationAction && !isSelf && !isTargetOwner;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: 6),
      child: Row(
        children: [
          ConcordAvatar(
            imageUrl: member.user.avatarUrl,
            name: displayName,
            size: ConcordAvatarSize.sm,
            presence: concordPresenceFor(member.user.status),
          ),
          const SizedBox(width: ConcordSpacing.sm),
          Expanded(
            child: Text(
              displayName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w500, color: colors.fgDefault),
            ),
          ),
          if (member.isMuted) ...[
            const SizedBox(width: ConcordSpacing.xs),
            Tooltip(
              message: 'Muted',
              child: Icon(Icons.mic_off_outlined, size: 15, color: colors.fgMuted),
            ),
          ],
          if (member.isTimedOut) ...[
            const SizedBox(width: ConcordSpacing.xs),
            Tooltip(
              message: 'Timed out until ${member.timedOutUntil}',
              child: Icon(Icons.schedule_outlined, size: 15, color: colors.fgMuted),
            ),
          ],
          if (canModerate)
            IconButton(
              icon: const Icon(Icons.more_vert, size: 18),
              tooltip: 'Moderate $displayName',
              onPressed: () => showMemberModerationSheet(
                context,
                ref,
                serverId: serverId,
                member: member,
                permissions: permissions,
              ),
            ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
