import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../providers/paged_list_controller.dart';
import '../../providers/server_member_list_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'server_member_row.dart';

class ServerMemberListScreen extends ConsumerWidget {
  const ServerMemberListScreen({super.key, required this.serverId});

  final String serverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serverMemberListControllerProvider(serverId));
    final controller = ref.read(serverMemberListControllerProvider(serverId).notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: _buildBody(context, state, controller),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PagedListState<ServerMemberSummary> state,
    PagedListController<ServerMemberSummary> controller,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.loadError != null && state.items.isEmpty) {
      return Center(
        child: ConcordEmptyState(
          icon: Icons.error_outline,
          title: "Couldn't load members",
          subtitle: state.loadError,
          action: ConcordButton(
            label: 'Try again',
            variant: ConcordButtonVariant.secondary,
            size: ConcordButtonSize.sm,
            onPressed: controller.retryInitialLoad,
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return const Center(
        child: ConcordEmptyState(
          icon: Icons.people_outline,
          title: 'No members',
          subtitle: 'This server has no members yet.',
        ),
      );
    }

    final colors = Theme.of(context).extension<ConcordColors>()!;
    final groups = _groupByPresence(state.items);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
      children: [
        for (final group in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(ConcordSpacing.md, ConcordSpacing.md, ConcordSpacing.md, ConcordSpacing.xs),
            child: Text(
              '${group.label.toUpperCase()} - ${group.members.length}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.fgMuted, letterSpacing: 0.5),
            ),
          ),
          for (final member in group.members) ServerMemberRow(serverId: serverId, member: member),
        ],
        if (state.hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.md),
            child: Center(
              child: state.isLoadingMore
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : ConcordButton(
                      label: 'Load more',
                      variant: ConcordButtonVariant.secondary,
                      size: ConcordButtonSize.sm,
                      onPressed: controller.loadMore,
                    ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.xs),
          child: Text(
            '${state.items.length} member${state.items.length == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 12, color: colors.fgMuted),
          ),
        ),
      ],
    );
  }

  List<_MemberGroup> _groupByPresence(List<ServerMemberSummary> members) {
    final online = <ServerMemberSummary>[];
    final idle = <ServerMemberSummary>[];
    final offline = <ServerMemberSummary>[];
    for (final member in members) {
      switch (member.user.status) {
        case PresenceStatus.online:
          online.add(member);
        case PresenceStatus.idle:
          idle.add(member);
        case PresenceStatus.doNotDisturb:
        case PresenceStatus.invisible:
        case PresenceStatus.offline:
          offline.add(member);
      }
    }
    return [
      if (online.isNotEmpty) _MemberGroup('Online', online),
      if (idle.isNotEmpty) _MemberGroup('Idle', idle),
      if (offline.isNotEmpty) _MemberGroup('Offline', offline),
    ];
  }
}

class _MemberGroup {
  const _MemberGroup(this.label, this.members);

  final String label;
  final List<ServerMemberSummary> members;
}
