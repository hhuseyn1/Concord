import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api.dart';
import '../../providers/api_providers.dart';
import '../../providers/server_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../servers/create_channel_sheet.dart';
import '../servers/invite_sheet.dart';
import '../servers/rename_channel_sheet.dart';
import '../servers/transfer_ownership_sheet.dart';
import 'server_rail_drawer.dart';
import 'user_panel_bar.dart';

class ChannelListScreen extends ConsumerWidget {
  const ChannelListScreen({super.key, required this.serverId});

  final String serverId;

  Future<void> _confirmLeaveServer(BuildContext context, WidgetRef ref, String serverName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave $serverName?'),
        content: const Text("This removes you from the server immediately. You'll need a new invite to rejoin later."),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Leave Server')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(serversServiceProvider).leaveServer(serverId);
      ref.invalidate(myServersProvider);
      if (context.mounted) context.go('/');
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not leave server: ${e.message}')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversAsync = ref.watch(myServersProvider);
    final channelsAsync = ref.watch(channelsProvider(serverId));
    final permissionsAsync = ref.watch(myPermissionsProvider(serverId));

    final serverName = serversAsync.maybeWhen(
      data: (servers) => servers.where((s) => s.id == serverId).firstOrNull?.name,
      orElse: () => null,
    );

    final permissions = permissionsAsync.maybeWhen(data: (p) => p, orElse: () => null);
    final canManageChannels = permissions?.hasManageChannels ?? false;
    final canManageInvites = permissions?.hasManageInvites ?? false;
    final isOwner = permissions?.isOwner ?? false;

    return Scaffold(
      endDrawer: const ServerRailDrawer(),
      appBar: AppBar(
        title: Text(serverName ?? 'Server'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Members',
            onPressed: () => context.push('/servers/$serverId/members'),
          ),
          if (permissions != null)
            PopupMenuButton<String>(
              tooltip: 'Server options',
              onSelected: (value) {
                switch (value) {
                  case 'invite':
                    showInviteSheet(context, ref, serverId: serverId);
                  case 'transfer':
                    showTransferOwnershipSheet(context, ref, serverId: serverId, serverName: serverName ?? 'this server');
                  case 'leave':
                    _confirmLeaveServer(context, ref, serverName ?? 'this server');
                }
              },
              itemBuilder: (context) => [
                if (canManageInvites)
                  const PopupMenuItem(value: 'invite', child: Text('Invite People')),
                if (isOwner) const PopupMenuItem(value: 'transfer', child: Text('Transfer Ownership')),
                if (!isOwner) const PopupMenuItem(value: 'leave', child: Text('Leave Server')),
              ],
            ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Servers',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: channelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: ConcordEmptyState(
                  icon: Icons.error_outline,
                  title: 'Couldn’t load channels',
                  subtitle: error is ApiException ? error.message : error.toString(),
                ),
              ),
              data: (channels) {
                final textChannels = channels.where((c) => c.type == ChannelType.text).toList();
                final voiceChannels = channels.where((c) => c.type == ChannelType.voice).toList();

                if (channels.isEmpty && !canManageChannels) {
                  return const Center(
                    child: ConcordEmptyState(
                      icon: Icons.tag,
                      title: 'No channels yet',
                      subtitle: 'Channels created on this server will show up here.',
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
                  children: [
                    _ChannelGroup(
                      label: 'Text',
                      serverId: serverId,
                      channels: textChannels,
                      canManage: canManageChannels,
                      defaultType: ChannelType.text,
                    ),
                    _ChannelGroup(
                      label: 'Voice',
                      serverId: serverId,
                      channels: voiceChannels,
                      canManage: canManageChannels,
                      defaultType: ChannelType.voice,
                    ),
                  ],
                );
              },
            ),
          ),
          const UserPanelBar(),
        ],
      ),
    );
  }
}

class _ChannelGroup extends ConsumerWidget {
  const _ChannelGroup({
    required this.label,
    required this.serverId,
    required this.channels,
    required this.canManage,
    required this.defaultType,
  });

  final String label;
  final String serverId;
  final List<ChannelResponse> channels;
  final bool canManage;
  final ChannelType defaultType;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, ChannelResponse channel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete #${channel.name}?'),
        content: const Text(
          "This removes the channel for everyone in the server immediately. All messages in it will be lost. This can't be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete Channel')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(channelsServiceProvider).deleteChannel(serverId, channel.id);
      ref.invalidate(channelsProvider(serverId));
      if (context.mounted) {
        final router = GoRouter.of(context);
        if (router.state.pathParameters['channelId'] == channel.id) {
          router.go('/servers/$serverId');
        }
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not delete channel: ${e.message}')));
      }
    }
  }

  Future<void> _openChannelActions(BuildContext context, WidgetRef ref, ChannelResponse channel) async {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename Channel'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showRenameChannelSheet(context, ref, channel: channel);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colors.danger),
              title: Text('Delete Channel', style: TextStyle(color: colors.danger)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmDelete(context, ref, channel);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(ConcordSpacing.lg, ConcordSpacing.md, ConcordSpacing.md, ConcordSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.fgMuted, letterSpacing: 0.5),
              ),
              if (canManage)
                ConcordIconButton(
                  icon: Icons.add,
                  tooltip: 'Create $label channel',
                  size: ConcordButtonSize.sm,
                  variant: ConcordButtonVariant.ghost,
                  onPressed: () => showCreateChannelSheet(context, ref, serverId: serverId, defaultType: defaultType),
                ),
            ],
          ),
        ),
        if (channels.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.lg),
            child: Text(
              'No ${label.toLowerCase()} channels yet.',
              style: TextStyle(fontSize: 13, color: colors.fgMuted),
            ),
          )
        else
          for (final channel in channels)
            ListTile(
              leading: Icon(
                channel.type == ChannelType.voice ? Icons.volume_up_outlined : Icons.tag,
                color: colors.fgMuted,
              ),
              title: Text(channel.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (channel.unreadCount > 0)
                    ConcordBadge(
                      label: channel.unreadCount > 99 ? '99+' : '${channel.unreadCount}',
                      variant: ConcordBadgeVariant.danger,
                    ),
                  if (canManage)
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 18),
                      tooltip: 'Channel options',
                      onPressed: () => _openChannelActions(context, ref, channel),
                    ),
                ],
              ),
              onTap: () => context.push('/servers/$serverId/channels/${channel.id}'),
            ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
