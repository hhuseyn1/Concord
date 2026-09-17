import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/paged_list_controller.dart';
import '../../providers/server_member_list_providers.dart';
import '../../theme/theme.dart';
import '../../utils/api_error_message.dart';
import '../../widgets/widgets.dart';
import 'server_member_row.dart';

class ServerMemberListScreen extends ConsumerWidget {
  const ServerMemberListScreen({super.key, required this.serverId});

  final String serverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serverMemberListControllerProvider(serverId));
    final controller = ref.read(serverMemberListControllerProvider(serverId).notifier);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.membersTitle)),
      body: _buildBody(context, l10n, state, controller),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
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
          title: l10n.couldNotLoadMembersTitle,
          subtitle: apiErrorMessage(l10n, state.loadError!),
          action: ConcordButton(
            label: l10n.tryAgainButton,
            variant: ConcordButtonVariant.secondary,
            size: ConcordButtonSize.sm,
            onPressed: controller.retryInitialLoad,
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: ConcordEmptyState(
          icon: Icons.people_outline,
          title: l10n.noMembersTitle,
          subtitle: l10n.noMembersSubtitle,
        ),
      );
    }

    final colors = Theme.of(context).extension<ConcordColors>()!;
    final type = ConcordTypography.of(context);
    final groups = _groupByPresence(l10n, state.items);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
      children: [
        for (final group in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(ConcordSpacing.md, ConcordSpacing.md, ConcordSpacing.md, ConcordSpacing.xs),
            child: Text(
              l10n.memberGroupHeader(group.label.toUpperCase(), group.members.length),
              style: TextStyle(fontSize: type.size(12), fontWeight: FontWeight.w600, color: colors.fgMuted, letterSpacing: 0.5),
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
                      label: l10n.loadMoreButton,
                      variant: ConcordButtonVariant.secondary,
                      size: ConcordButtonSize.sm,
                      onPressed: controller.loadMore,
                    ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.xs),
          child: Text(
            l10n.memberCountLabel(state.items.length),
            style: TextStyle(fontSize: type.size(12), color: colors.fgMuted),
          ),
        ),
      ],
    );
  }

  List<_MemberGroup> _groupByPresence(AppLocalizations l10n, List<ServerMemberSummary> members) {
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
      if (online.isNotEmpty) _MemberGroup(l10n.statusOnline, online),
      if (idle.isNotEmpty) _MemberGroup(l10n.statusIdle, idle),
      if (offline.isNotEmpty) _MemberGroup(l10n.statusOffline, offline),
    ];
  }
}

class _MemberGroup {
  const _MemberGroup(this.label, this.members);

  final String label;
  final List<ServerMemberSummary> members;
}
