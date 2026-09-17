import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/notifications_controller.dart';
import '../../providers/user_providers.dart';
import '../../theme/theme.dart';
import '../../utils/api_error_message.dart';
import '../../utils/message_time_format.dart';
import '../../widgets/widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsScreenTitle),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => controller.markAllRead(),
              child: Text(l10n.markAllReadButton),
            ),
        ],
      ),
      body: _NotificationsBody(state: state, controller: controller),
    );
  }
}

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody({required this.state, required this.controller});

  final NotificationsState state;
  final NotificationsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.loadError != null && state.items.isEmpty) {
      return Center(
        child: ConcordEmptyState(
          icon: Icons.error_outline,
          title: l10n.couldNotLoadNotificationsTitle,
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
          icon: Icons.notifications_none,
          title: l10n.noNotificationsYetTitle,
          subtitle: l10n.noNotificationsYetSubtitle,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          if (!state.isLoadingMore) {
            WidgetsBinding.instance.addPostFrameCallback((_) => controller.loadMore());
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: ConcordSpacing.md),
            child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        return _NotificationRow(notification: state.items[index], controller: controller);
      },
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.controller});

  final NotificationResponse notification;
  final NotificationsController controller;

  String _text(AppLocalizations l10n) {
    final name = displayNameFor(notification.relatedUser, fallback: l10n.someoneFallback);
    return switch (notification.type) {
      NotificationType.friendRequestReceived => l10n.notifFriendRequestReceived(name),
      NotificationType.friendRequestAccepted => l10n.notifFriendRequestAccepted(name),
      NotificationType.missedCall => l10n.notifMissedCall(name),
      NotificationType.mention => l10n.notifMention(name),
      NotificationType.friendRequestDeclined => l10n.notifFriendRequestDeclined(name),
      NotificationType.friendRequestCancelled => l10n.notifFriendRequestCancelled(name),
      NotificationType.directMessageReceived => l10n.notifMessageReceived(name),
    };
  }

  IconData get _icon => switch (notification.type) {
    NotificationType.friendRequestReceived => Icons.person_add_outlined,
    NotificationType.friendRequestAccepted => Icons.people_outline,
    NotificationType.missedCall => Icons.call_missed,
    NotificationType.mention => Icons.alternate_email,
    NotificationType.friendRequestDeclined => Icons.person_remove_outlined,
    NotificationType.friendRequestCancelled => Icons.person_remove_outlined,
    NotificationType.directMessageReceived => Icons.chat_bubble_outline,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: notification.isRead ? null : () => controller.markRead(notification.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.sm),
        child: Row(
          children: [
            notification.relatedUser != null
                ? ConcordAvatar(
                    imageUrl: notification.relatedUser!.avatarUrl,
                    name: displayNameFor(notification.relatedUser),
                    size: ConcordAvatarSize.md,
                  )
                : CircleAvatar(
                    radius: 20,
                    backgroundColor: colors.fgDefault.withValues(alpha: 0.16),
                    child: Icon(_icon, size: 18, color: colors.fgMuted),
                  ),
            const SizedBox(width: ConcordSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _text(l10n),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.fgDefault,
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w500,
                    ),
                  ),
                  Text(
                    formatGroupTimestamp(l10n, notification.created),
                    style: textTheme.bodySmall?.copyWith(color: colors.fgMuted),
                  ),
                ],
              ),
            ),
            if (!notification.isRead) ...[
              const SizedBox(width: ConcordSpacing.sm),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: colors.brand),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
