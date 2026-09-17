import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.leaveServerConfirmTitle(serverName),
      message: l10n.leaveServerConfirmMessage,
      confirmLabel: l10n.leaveServerButton,
    );
    if (confirmed != true) return;
    try {
      await ref.read(serversServiceProvider).leaveServer(serverId);
      ref.invalidate(myServersProvider);
      if (context.mounted) context.go('/');
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorLeaveServerFailed(e.message))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
        title: Text(serverName ?? l10n.serverFallbackTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: l10n.membersTooltip,
            onPressed: () => context.push('/servers/$serverId/members'),
          ),
          if (permissions != null)
            PopupMenuButton<String>(
              tooltip: l10n.serverOptionsTooltip,
              onSelected: (value) {
                switch (value) {
                  case 'invite':
                    showInviteSheet(context, ref, serverId: serverId);
                  case 'transfer':
                    showTransferOwnershipSheet(
                      context,
                      ref,
                      serverId: serverId,
                      serverName: serverName ?? l10n.thisServerFallback,
                    );
                  case 'leave':
                    _confirmLeaveServer(context, ref, serverName ?? l10n.thisServerFallback);
                }
              },
              itemBuilder: (context) => [
                if (canManageInvites)
                  PopupMenuItem(value: 'invite', child: Text(l10n.invitePeopleMenuItem)),
                if (isOwner) PopupMenuItem(value: 'transfer', child: Text(l10n.transferOwnershipMenuItem)),
                if (!isOwner) PopupMenuItem(value: 'leave', child: Text(l10n.leaveServerButton)),
              ],
            ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: l10n.serversTooltip,
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
                  title: l10n.couldNotLoadChannelsTitle,
                  subtitle: error is ApiException ? error.message : error.toString(),
                ),
              ),
              data: (channels) {
                final textChannels = channels.where((c) => c.type == ChannelType.text).toList();
                final voiceChannels = channels.where((c) => c.type == ChannelType.voice).toList();

                if (channels.isEmpty && !canManageChannels) {
                  return Center(
                    child: ConcordEmptyState(
                      icon: Icons.tag,
                      title: l10n.noChannelsYetTitle,
                      subtitle: l10n.noChannelsYetSubtitle,
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
                  children: [
                    _ChannelGroup(
                      label: l10n.textChannelsLabel,
                      serverId: serverId,
                      channels: textChannels,
                      canManage: canManageChannels,
                      defaultType: ChannelType.text,
                    ),
                    _ChannelGroup(
                      label: l10n.voiceChannelsLabel,
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteChannelConfirmTitle(channel.name),
      message: l10n.deleteChannelConfirmMessage,
      confirmLabel: l10n.deleteChannelButton,
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
            .showSnackBar(SnackBar(content: Text(l10n.errorDeleteChannelFailed(e.message))));
      }
    }
  }

  Future<void> _openChannelActions(BuildContext context, WidgetRef ref, ChannelResponse channel) async {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.renameChannelMenuItem),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showRenameChannelSheet(context, ref, channel: channel);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colors.danger),
              title: Text(l10n.deleteChannelButton, style: TextStyle(color: colors.danger)),
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
    final type = ConcordTypography.of(context);
    final l10n = AppLocalizations.of(context);

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
                style: TextStyle(fontSize: type.size(12), fontWeight: FontWeight.w600, color: colors.fgMuted, letterSpacing: 0.5),
              ),
              if (canManage)
                ConcordIconButton(
                  icon: Icons.add,
                  tooltip: l10n.createChannelTooltip(label),
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
              l10n.noChannelsOfTypeYet(label.toLowerCase()),
              style: TextStyle(fontSize: type.size(13), color: colors.fgMuted),
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
                      tooltip: l10n.channelOptionsTooltip,
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
