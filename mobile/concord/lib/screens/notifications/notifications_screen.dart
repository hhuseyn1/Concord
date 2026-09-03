import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../providers/notifications_controller.dart';
import '../../providers/user_providers.dart';
import '../../theme/theme.dart';
import '../../utils/message_time_format.dart';
import '../../widgets/widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => controller.markAllRead(),
              child: const Text('Mark all read'),
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
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.loadError != null && state.items.isEmpty) {
      return Center(
        child: ConcordEmptyState(
          icon: Icons.error_outline,
          title: "Couldn't load notifications",
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
          icon: Icons.notifications_none,
          title: 'No notifications yet',
          subtitle: "Friend requests, missed calls, and mentions will show up here.",
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

  String get _text {
    final name = displayNameFor(notification.relatedUser, fallback: 'Someone');
    return switch (notification.type) {
      NotificationType.friendRequestReceived => '$name sent you a friend request',
      NotificationType.friendRequestAccepted => '$name accepted your friend request',
      NotificationType.missedCall => 'Missed call from $name',
      NotificationType.mention => '$name mentioned you',
      NotificationType.friendRequestDeclined => '$name declined your friend request',
      NotificationType.friendRequestCancelled => '$name cancelled their friend request',
    };
  }

  IconData get _icon => switch (notification.type) {
    NotificationType.friendRequestReceived => Icons.person_add_outlined,
    NotificationType.friendRequestAccepted => Icons.people_outline,
    NotificationType.missedCall => Icons.call_missed,
    NotificationType.mention => Icons.alternate_email,
    NotificationType.friendRequestDeclined => Icons.person_remove_outlined,
    NotificationType.friendRequestCancelled => Icons.person_remove_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;

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
                    backgroundColor: colors.surfaceRail,
                    child: Icon(_icon, size: 18, color: colors.fgMuted),
                  ),
            const SizedBox(width: ConcordSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _text,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.fgDefault,
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w500,
                    ),
                  ),
                  Text(
                    formatGroupTimestamp(notification.created),
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
