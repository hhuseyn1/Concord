import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/conversation_list_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'direct_message_screen.dart';

class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(conversationsControllerProvider);
    final controller = ref.read(conversationsControllerProvider.notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.loadError != null && state.items.isEmpty) {
      return Center(
        child: ConcordEmptyState(
          icon: Icons.error_outline,
          title: l10n.couldNotLoadConversationsTitle,
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
          icon: Icons.mail_outline,
          title: l10n.noConversationsYetTitle,
          subtitle: l10n.noConversationsYetSubtitle,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.xs),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return Padding(
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
          );
        }

        final conversation = state.items[index];
        final displayName = displayNameFor(conversation.otherUser);
        final lastMessage = conversation.lastMessage;
        final preview = lastMessage == null
            ? null
            : ((lastMessage.content?.isNotEmpty ?? false) ? lastMessage.content : l10n.sentAttachmentPreview);

        return ListTile(
          leading: ConcordAvatar(
            imageUrl: conversation.otherUser.avatarUrl,
            name: displayName,
            presence: concordPresenceFor(conversation.otherUser.status),
          ),
          title: Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: preview == null
              ? null
              : Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.fgMuted)),
          trailing: conversation.unreadCount > 0
              ? ConcordBadge(
                  label: conversation.unreadCount > 99 ? '99+' : '${conversation.unreadCount}',
                  variant: ConcordBadgeVariant.danger,
                )
              : null,
          onTap: () => context.push(
            '/dm/${conversation.id}',
            extra: DirectMessageRouteArgs(
              otherUserName: displayName,
              otherUserAvatarUrl: conversation.otherUser.avatarUrl,
            ),
          ),
        );
      },
    );
  }
}
