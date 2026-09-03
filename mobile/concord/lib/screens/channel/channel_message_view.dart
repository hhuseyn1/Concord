import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/message_like.dart';
import '../../providers/auth_controller.dart';
import '../../providers/message_providers.dart';
import '../messaging/message_composer.dart';
import '../messaging/message_list_view.dart';
import '../messaging/typing_indicator_bar.dart';

class ChannelMessageView extends ConsumerStatefulWidget {
  const ChannelMessageView({super.key, required this.serverId, required this.channelId});

  final String serverId;
  final String channelId;

  @override
  ConsumerState<ChannelMessageView> createState() => _ChannelMessageViewState();
}

class _ChannelMessageViewState extends ConsumerState<ChannelMessageView> {
  final _scrollController = ScrollController();
  MessageLike? _replyingTo;

  @override
  void dispose() {
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
    final key = ChannelKey(widget.serverId, widget.channelId);
    final controller = ref.read(messagesControllerProvider(key).notifier);
    final state = ref.watch(messagesControllerProvider(key));
    final currentUserId = ref.watch(authControllerProvider.select((state) => state.profile?.id));

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
            serverId: widget.serverId,
            sourceChannelId: widget.channelId,
          ),
        ),
        TypingIndicatorBar(typingUserIds: state.typingUserIds),
        MessageComposer(
          controller: controller,
          draftKey: widget.channelId,
          replyingTo: _replyingTo,
          onCancelReply: () => setState(() => _replyingTo = null),
          onSent: _scrollToBottom,
          hintText: 'Message this channel…',
          serverId: widget.serverId,
        ),
      ],
    );
  }
}
