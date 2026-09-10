import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../providers/conversation_list_providers.dart';
import '../../providers/friends_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../direct_messages/direct_message_screen.dart';
import 'friend_row.dart';

class FriendsTab extends ConsumerStatefulWidget {
  const FriendsTab({super.key});

  @override
  ConsumerState<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends ConsumerState<FriendsTab> {
  String? _startingDmForUserId;
  bool _blocking = false;

  Future<void> _handleMessage(PublicProfileResponse user) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _startingDmForUserId = user.id);
    try {
      final conversation = await ref.read(directMessagesServiceProvider).createOrGetConversation(user.id);
      if (!mounted) return;
      ref.read(conversationsControllerProvider.notifier).upsertConversation(conversation);
      context.push(
        '/dm/${conversation.id}',
        extra: DirectMessageRouteArgs(otherUserName: displayNameFor(user), otherUserAvatarUrl: user.avatarUrl),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorStartConversationFailed(e.message))));
    } finally {
      if (mounted) setState(() => _startingDmForUserId = null);
    }
  }

  Future<void> _confirmBlock(PublicProfileResponse user) async {
    final l10n = AppLocalizations.of(context);
    final displayName = displayNameFor(user);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.blockConfirmTitle),
        content: Text(l10n.blockConfirmMessage(displayName)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancelButton)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.blockUserButton)),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _blocking = true);
    try {
      await ref.read(friendsServiceProvider).block(user.id);
      if (!mounted) return;
      invalidateFriendsState(ref);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.blockedSnackbar(displayName))));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorBlockUserFailed(e.message))));
    } finally {
      if (mounted) setState(() => _blocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(friendsListControllerProvider);
    final controller = ref.read(friendsListControllerProvider.notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.loadError != null && state.items.isEmpty) {
      return Center(
        child: ConcordEmptyState(
          icon: Icons.error_outline,
          title: l10n.couldNotLoadFriendsTitle,
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
          icon: Icons.people_outline,
          title: l10n.noFriendsYetTitle,
          subtitle: l10n.noFriendsYetSubtitle,
        ),
      );
    }

    final friends = [...state.items]
      ..sort((a, b) => presenceSortWeight(a.status).compareTo(presenceSortWeight(b.status)));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md),
          child: Text(
            '${l10n.allFriendsHeader}${l10n.sectionCountSuffix(friends.length)}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.fgMuted, letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: ConcordSpacing.xs),
        for (final user in friends)
          FriendRow(
            user: user,
            actions: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_startingDmForUserId == user.id)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  ConcordIconButton(
                    icon: Icons.chat_bubble_outline,
                    tooltip: l10n.messageTooltip,
                    size: ConcordButtonSize.sm,
                    onPressed: _startingDmForUserId != null ? null : () => _handleMessage(user),
                  ),
                ConcordIconButton(
                  icon: Icons.person_remove_outlined,
                  tooltip: l10n.blockTooltip,
                  size: ConcordButtonSize.sm,
                  onPressed: _blocking ? null : () => _confirmBlock(user),
                ),
              ],
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
