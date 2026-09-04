import 'package:flutter/material.dart';

import '../../api/models/message_like.dart';
import '../../providers/message_thread_controller.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'message_tile.dart';

class MessageListView extends StatefulWidget {
  const MessageListView({
    super.key,
    required this.messages,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.loadError,
    required this.currentUserId,
    required this.scrollController,
    required this.controller,
    required this.onReply,
    required this.onLoadMore,
    required this.onRetryInitialLoad,
    this.threadNoun = 'channel',
    this.emptyTitle = 'No messages yet',
    this.emptySubtitle = 'Say something to get the conversation started.',
    this.serverId,
    this.sourceChannelId,
    this.sourceConversationId,
    this.otherReadAt,
  });

  final List<MessageLike> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? loadError;
  final String? currentUserId;
  final ScrollController scrollController;
  final MessageThreadController controller;
  final ValueChanged<MessageLike> onReply;
  final VoidCallback onLoadMore;
  final VoidCallback onRetryInitialLoad;

  final String threadNoun;
  final String emptyTitle;
  final String emptySubtitle;

  final String? serverId;

  final String? sourceChannelId;
  final String? sourceConversationId;

  final DateTime? otherReadAt;

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView> {
  static const _groupWindow = Duration(minutes: 5);
  static const _nearBottomThreshold = 150.0;

  bool _isNearBottom = true;
  bool _pendingOlderLoad = false;
  double _maxScrollExtentBeforeLoad = 0;
  String? _prevNewestId;
  bool _hasScrolledInitially = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MessageListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousMessages = oldWidget.messages;
    final nextMessages = widget.messages;
    final newestId = nextMessages.isEmpty ? null : nextMessages.last.id;
    final wasEmpty = previousMessages.isEmpty;
    final isFirstLoad = wasEmpty && nextMessages.isNotEmpty && !_hasScrolledInitially;
    final appendedWhileNearBottom =
        !isFirstLoad && !_pendingOlderLoad && newestId != null && newestId != _prevNewestId && _isNearBottom;

    if (isFirstLoad) {
      _hasScrolledInitially = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottomNow());
    } else if (appendedWhileNearBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottomNow(animate: true));
    } else if (_pendingOlderLoad && nextMessages.length > previousMessages.length) {
      _pendingOlderLoad = false;
      final before = _maxScrollExtentBeforeLoad;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!widget.scrollController.hasClients) return;
        final after = widget.scrollController.position.maxScrollExtent;
        widget.scrollController.jumpTo(widget.scrollController.offset + (after - before));
      });
    }
    _prevNewestId = newestId;
  }

  void _handleScroll() {
    if (!widget.scrollController.hasClients) return;
    final position = widget.scrollController.position;
    final nearBottom = position.maxScrollExtent - position.pixels < _nearBottomThreshold;
    if (nearBottom != _isNearBottom && mounted) {
      setState(() => _isNearBottom = nearBottom);
    }
  }

  void _scrollToBottomNow({bool animate = false}) {
    if (!widget.scrollController.hasClients) return;
    final target = widget.scrollController.position.maxScrollExtent;
    if (animate) {
      widget.scrollController.animateTo(target, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    } else {
      widget.scrollController.jumpTo(target);
    }
  }

  void _handleLoadOlder() {
    if (widget.scrollController.hasClients) {
      _pendingOlderLoad = true;
      _maxScrollExtentBeforeLoad = widget.scrollController.position.maxScrollExtent;
    }
    widget.onLoadMore();
  }

  List<List<MessageLike>> _groupMessages(List<MessageLike> messages) {
    final groups = <List<MessageLike>>[];
    for (final message in messages) {
      final lastGroup = groups.isEmpty ? null : groups.last;
      final lastMessage = (lastGroup != null && lastGroup.isNotEmpty) ? lastGroup.last : null;
      final sameSender = lastMessage != null && lastMessage.sender.id == message.sender.id;
      final withinWindow =
          lastMessage != null && message.created.difference(lastMessage.created).abs() < _groupWindow;
      if (lastGroup != null && sameSender && withinWindow) {
        lastGroup.add(message);
      } else {
        groups.add([message]);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;

    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.loadError != null && widget.messages.isEmpty) {
      return Center(
        child: ConcordEmptyState(
          icon: Icons.error_outline,
          title: "Couldn't load messages",
          subtitle: widget.loadError,
          action: ConcordButton(
            label: 'Try again',
            variant: ConcordButtonVariant.secondary,
            size: ConcordButtonSize.sm,
            onPressed: widget.onRetryInitialLoad,
          ),
        ),
      );
    }

    if (widget.messages.isEmpty) {
      return Center(
        child: ConcordEmptyState(
          icon: Icons.chat_bubble_outline,
          title: widget.emptyTitle,
          subtitle: widget.emptySubtitle,
        ),
      );
    }

    final groups = _groupMessages(widget.messages);
    final messageById = {for (final m in widget.messages) m.id: m};

    String? lastOwnMessageId;
    if (widget.currentUserId != null) {
      for (var i = widget.messages.length - 1; i >= 0; i--) {
        if (widget.messages[i].sender.id == widget.currentUserId) {
          lastOwnMessageId = widget.messages[i].id;
          break;
        }
      }
    }
    final lastOwnMessage = lastOwnMessageId == null ? null : messageById[lastOwnMessageId];
    final otherReadAt = widget.otherReadAt;
    final showReadReceipt = lastOwnMessage != null &&
        otherReadAt != null &&
        !otherReadAt.isBefore(lastOwnMessage.created);

    return Stack(
      children: [
        ListView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.only(bottom: ConcordSpacing.md),
          itemCount: groups.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.md),
                child: Center(
                  child: widget.hasMore
                      ? (widget.isLoadingMore
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : ConcordButton(
                              label: 'Load older messages',
                              variant: ConcordButtonVariant.secondary,
                              size: ConcordButtonSize.sm,
                              onPressed: _handleLoadOlder,
                            ))
                      : Text(
                          "You've reached the beginning of this ${widget.threadNoun}.",
                          style: TextStyle(fontSize: 12, color: colors.fgMuted),
                        ),
                ),
              );
            }

            final group = groups[index - 1];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < group.length; i++)
                  MessageTile(
                    key: ValueKey(group[i].id),
                    message: group[i],
                    showHeader: i == 0,
                    isOwn: widget.currentUserId != null && group[i].sender.id == widget.currentUserId,
                    currentUserId: widget.currentUserId,
                    replyToMessage: group[i].replyToMessageId != null ? messageById[group[i].replyToMessageId] : null,
                    controller: widget.controller,
                    threadNoun: widget.threadNoun,
                    onReply: widget.onReply,
                    serverId: widget.serverId,
                    sourceChannelId: widget.sourceChannelId,
                    sourceConversationId: widget.sourceConversationId,
                  ),
                if (showReadReceipt && group.last.id == lastOwnMessageId)
                  Padding(
                    padding: const EdgeInsets.only(left: 52, right: ConcordSpacing.lg, top: 2),
                    child: Text('Seen', style: TextStyle(fontSize: 11, color: colors.fgMuted)),
                  ),
              ],
            );
          },
        ),
        if (!_isNearBottom)
          Positioned(
            right: ConcordSpacing.lg,
            bottom: ConcordSpacing.lg,
            child: ConcordIconButton(
              icon: Icons.arrow_downward,
              tooltip: 'Scroll to bottom',
              variant: ConcordButtonVariant.secondary,
              onPressed: () => _scrollToBottomNow(animate: true),
            ),
          ),
      ],
    );
  }
}
