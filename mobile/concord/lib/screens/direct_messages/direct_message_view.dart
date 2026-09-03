import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/message_like.dart';
import '../../providers/auth_controller.dart';
import '../../providers/conversation_list_providers.dart';
import '../../providers/direct_message_providers.dart';
import '../../providers/user_providers.dart';
import '../messaging/message_composer.dart';
import '../messaging/message_list_view.dart';
import '../messaging/typing_indicator_bar.dart';

class DirectMessageView extends ConsumerStatefulWidget {
  const DirectMessageView({
    super.key,
    required this.conversationId,
    this.otherUserName,
    this.otherUserAvatarUrl,
  });

  final String conversationId;
  final String? otherUserName;
  final String? otherUserAvatarUrl;

  @override
  ConsumerState<DirectMessageView> createState() => _DirectMessageViewState();
}

class _DirectMessageViewState extends ConsumerState<DirectMessageView> {
  final _scrollController = ScrollController();
  MessageLike? _replyingTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeDmConversationIdProvider.notifier).state = widget.conversationId;
      ref.read(conversationsControllerProvider.notifier).markConversationRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    if (ref.read(activeDmConversationIdProvider) == widget.conversationId) {
      ref.read(activeDmConversationIdProvider.notifier).state = null;
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(directMessagesControllerProvider(widget.conversationId).notifier);
    final state = ref.watch(directMessagesControllerProvider(widget.conversationId));
    final currentUserId = ref.watch(authControllerProvider.select((s) => s.profile?.id));

    final otherUserName = widget.otherUserName ??
        state.messages.reversed
            .where((m) => m.sender.id != currentUserId)
            .map((m) => displayNameFor(m.sender))
            .firstOrNull;

    return Column(
      children: [
        Expanded(
          child: MessageListView(
            messages: state.messages,
            isLoading: state.isLoading,
            isLoadingMore: state.isLoadingMore,
            hasMore: state.hasMore,
            loadError: state.loadError,
            currentUserId: currentUserId,
            scrollController: _scrollController,
            controller: controller,
            onReply: (message) => setState(() => _replyingTo = message),
            onLoadMore: controller.loadMore,
            onRetryInitialLoad: controller.retryInitialLoad,
            threadNoun: 'conversation',
            emptyTitle: 'No messages yet',
            emptySubtitle: 'Say hi to start the conversation.',
            otherReadAt: state.otherReadAt,
            sourceConversationId: widget.conversationId,
          ),
        ),
        TypingIndicatorBar(typingUserIds: state.typingUserIds),
        MessageComposer(
          controller: controller,
          draftKey: 'dm:${widget.conversationId}',
          replyingTo: _replyingTo,
          onCancelReply: () => setState(() => _replyingTo = null),
          onSent: _scrollToBottom,
          hintText: otherUserName != null ? 'Message @$otherUserName…' : 'Message…',
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
