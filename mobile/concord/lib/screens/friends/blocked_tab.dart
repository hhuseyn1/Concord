import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../providers/api_providers.dart';
import '../../providers/friends_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'friend_row.dart';

class BlockedTab extends ConsumerStatefulWidget {
  const BlockedTab({super.key});

  @override
  ConsumerState<BlockedTab> createState() => _BlockedTabState();
}

class _BlockedTabState extends ConsumerState<BlockedTab> {
  String? _unblockingUserId;

  Future<void> _unblock(PublicProfileResponse user) async {
    setState(() => _unblockingUserId = user.id);
    try {
      await ref.read(friendsServiceProvider).unblock(user.id);
      if (!mounted) return;
      invalidateFriendsState(ref);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${displayNameFor(user)} can interact with you again.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not unblock user: ${e.message}')));
    } finally {
      if (mounted) setState(() => _unblockingUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final state = ref.watch(blockedListControllerProvider);
    final controller = ref.read(blockedListControllerProvider.notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.loadError != null && state.items.isEmpty) {
      return Center(
        child: ConcordEmptyState(
          icon: Icons.error_outline,
          title: "Couldn't load blocked users",
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
          icon: Icons.block,
          title: 'No blocked users',
          subtitle: 'Users you block will show up here. Blocking removes them from your friends and pending '
              "requests, and they can't message or friend-request you again unless you unblock them.",
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md),
          child: Text(
            'BLOCKED - ${state.items.length}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.fgMuted, letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: ConcordSpacing.xs),
        for (final user in state.items)
          FriendRow(
            user: user,
            showPresence: false,
            actions: ConcordButton(
              label: 'Unblock',
              variant: ConcordButtonVariant.secondary,
              size: ConcordButtonSize.sm,
              loading: _unblockingUserId == user.id,
              onPressed: _unblockingUserId != null ? null : () => _unblock(user),
            ),
          ),
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
      ],
    );
  }
}
