import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.unblockConfirmTitle(displayNameFor(user)),
      message: l10n.unblockConfirmMessage,
      confirmLabel: l10n.unblockButton,
      isDestructive: false,
    );
    if (confirmed != true) return;
    if (!mounted) return;
    setState(() => _unblockingUserId = user.id);
    try {
      await ref.read(friendsServiceProvider).unblock(user.id);
      if (!mounted) return;
      invalidateFriendsState(ref);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.unblockedSnackbar(displayNameFor(user)))));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorUnblockFailed(e.message))));
    } finally {
      if (mounted) setState(() => _unblockingUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(blockedListControllerProvider);
    final controller = ref.read(blockedListControllerProvider.notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.loadError != null && state.items.isEmpty) {
      return Center(
        child: ConcordEmptyState(
          icon: Icons.error_outline,
          title: l10n.couldNotLoadBlockedTitle,
          subtitle: state.loadError,
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
          icon: Icons.block,
          title: l10n.noBlockedUsersTitle,
          subtitle: l10n.noBlockedUsersSubtitle,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md),
          child: Text(
            '${l10n.blockedHeader}${l10n.sectionCountSuffix(state.items.length)}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.fgMuted, letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: ConcordSpacing.xs),
        for (final user in state.items)
          FriendRow(
            user: user,
            showPresence: false,
            actions: ConcordButton(
              label: l10n.unblockButton,
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
                      label: l10n.loadMoreButton,
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
