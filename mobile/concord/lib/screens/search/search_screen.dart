import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api.dart';
import '../../providers/search_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/theme.dart';
import '../../utils/message_time_format.dart';
import '../../widgets/widgets.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final state = ref.watch(searchControllerProvider);
    final notifier = ref.read(searchControllerProvider.notifier);
    final trimmedLength = state.query.trim().length;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search messages…',
            border: InputBorder.none,
          ),
          onChanged: notifier.setQuery,
        ),
      ),
      body: Builder(
        builder: (context) {
          if (trimmedLength > 0 && trimmedLength < 2) {
            return const Center(child: Text('Keep typing…'));
          }
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(
              child: ConcordEmptyState(
                icon: Icons.error_outline,
                title: "Couldn't search",
                subtitle: state.error,
              ),
            );
          }
          if (trimmedLength == 0) {
            return const Center(
              child: ConcordEmptyState(
                icon: Icons.search,
                title: 'Search across your servers and DMs',
                subtitle: 'Type at least 2 characters to start searching.',
              ),
            );
          }
          if (state.results.isEmpty) {
            return const Center(
              child: ConcordEmptyState(icon: Icons.search_off, title: 'No results'),
            );
          }
          return ListView.separated(
            itemCount: state.results.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: colors.borderSubtle),
            itemBuilder: (context, index) {
              final result = state.results[index];
              final senderName = displayNameFor(result.sender);
              return ListTile(
                leading: ConcordAvatar(imageUrl: result.sender.avatarUrl, name: senderName, size: ConcordAvatarSize.sm),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(senderName, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.fgDefault)),
                    ),
                    const SizedBox(width: ConcordSpacing.xs),
                    Icon(
                      result.sourceType == MessageSourceType.channel ? Icons.tag : Icons.chat_bubble_outline,
                      size: 12,
                      color: colors.fgMuted,
                    ),
                    const SizedBox(width: ConcordSpacing.xs),
                    Text(formatAbsoluteTimestamp(result.created), style: TextStyle(color: colors.fgMuted, fontSize: 11)),
                  ],
                ),
                subtitle: Text(
                  result.content?.isNotEmpty == true ? result.content! : '(no text content)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.fgMuted),
                ),
                onTap: () => _openResult(context, result),
              );
            },
          );
        },
      ),
    );
  }

  void _openResult(BuildContext context, GlobalSearchResultResponse result) {
    if (result.sourceType == MessageSourceType.channel) {
      context.push('/servers/${result.serverId}/channels/${result.channelId}');
    } else {
      context.push('/dm/${result.conversationId}');
    }
  }
}
