import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/conversation_list_providers.dart';
import '../../providers/message_thread_controller.dart';
import '../../providers/server_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

Future<void> showForwardMessageSheet(
  BuildContext context, {
  required MessageLike message,
  required MessageThreadController controller,
  String? sourceChannelId,
  String? sourceConversationId,
}) {
  final colors = Theme.of(context).extension<ConcordColors>()!;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.surfaceFloating,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ConcordRadii.lg)),
    ),
    builder: (sheetContext) => _ForwardMessageSheet(
      message: message,
      controller: controller,
      sourceChannelId: sourceChannelId,
      sourceConversationId: sourceConversationId,
    ),
  );
}

class _ForwardMessageSheet extends ConsumerStatefulWidget {
  const _ForwardMessageSheet({
    required this.message,
    required this.controller,
    this.sourceChannelId,
    this.sourceConversationId,
  });

  final MessageLike message;
  final MessageThreadController controller;
  final String? sourceChannelId;
  final String? sourceConversationId;

  @override
  ConsumerState<_ForwardMessageSheet> createState() => _ForwardMessageSheetState();
}

class _ForwardMessageSheetState extends ConsumerState<_ForwardMessageSheet> {
  final _searchController = TextEditingController();
  bool _forwarding = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _forwardTo({String? channelId, String? conversationId}) async {
    if (_forwarding) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _forwarding = true;
      _error = null;
    });
    try {
      await widget.controller.forwardMessage(
        widget.message.id,
        targetChannelId: channelId,
        targetConversationId: conversationId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.messageForwardedSnackbar)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _forwarding = false;
        _error = e.message.isNotEmpty ? e.message : l10n.errorForwardMessageFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final type = ConcordTypography.of(context);
    final l10n = AppLocalizations.of(context);
    final query = _searchController.text.trim().toLowerCase();
    final serversAsync = ref.watch(myServersProvider);
    final conversationsState = ref.watch(conversationsControllerProvider);

    final filteredConversations = conversationsState.items
        .where((c) => c.id != widget.sourceConversationId)
        .where((c) => query.isEmpty || displayNameFor(c.otherUser).toLowerCase().contains(query))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: ConcordSpacing.lg,
        right: ConcordSpacing.lg,
        top: ConcordSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + ConcordSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.forwardMessageTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.forwardMessageSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.fgMuted),
            ),
            const SizedBox(height: ConcordSpacing.md),
            ConcordTextField(
              controller: _searchController,
              hint: l10n.forwardSearchHint,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: ConcordSpacing.sm),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: colors.danger, fontSize: type.size(12))),
              const SizedBox(height: ConcordSpacing.sm),
            ],
            Flexible(
              child: AbsorbPointer(
                absorbing: _forwarding,
                child: Opacity(
                  opacity: _forwarding ? 0.5 : 1,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.xs),
                        child: Text(
                          l10n.channelsSectionHeader,
                          style: TextStyle(
                            fontSize: type.size(11),
                            fontWeight: FontWeight.w600,
                            color: colors.fgMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      serversAsync.when(
                        data: (servers) {
                          final matching = servers
                              .where((s) => query.isEmpty || s.name.toLowerCase().contains(query))
                              .toList();
                          if (matching.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
                              child: Text(
                                servers.isEmpty ? l10n.notInAnyServersText : l10n.noMatchingServersText,
                                style: TextStyle(fontSize: type.size(13), color: colors.fgMuted),
                              ),
                            );
                          }
                          return Column(
                            children: [
                              for (final server in matching)
                                _ServerChannelsExpansion(
                                  server: server,
                                  query: query,
                                  excludeChannelId: widget.sourceChannelId,
                                  onPick: (channelId) => _forwardTo(channelId: channelId),
                                ),
                            ],
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: ConcordSpacing.md),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        error: (error, stackTrace) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
                          child: Text(l10n.couldNotLoadYourServersText, style: TextStyle(fontSize: type.size(13), color: colors.danger)),
                        ),
                      ),
                      const SizedBox(height: ConcordSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.xs),
                        child: Text(
                          l10n.directMessagesSectionHeader,
                          style: TextStyle(
                            fontSize: type.size(11),
                            fontWeight: FontWeight.w600,
                            color: colors.fgMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (filteredConversations.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
                          child: Text(l10n.noMatchingConversationsText, style: TextStyle(fontSize: type.size(13), color: colors.fgMuted)),
                        )
                      else
                        for (final conversation in filteredConversations)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ConcordAvatar(
                              imageUrl: conversation.otherUser.avatarUrl,
                              name: displayNameFor(conversation.otherUser),
                              size: ConcordAvatarSize.sm,
                            ),
                            title: Text(displayNameFor(conversation.otherUser)),
                            trailing: Icon(Icons.chat_bubble_outline, size: 16, color: colors.fgMuted),
                            onTap: () => _forwardTo(conversationId: conversation.id),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerChannelsExpansion extends ConsumerWidget {
  const _ServerChannelsExpansion({
    required this.server,
    required this.query,
    required this.onPick,
    this.excludeChannelId,
  });

  final ServerResponse server;
  final String query;
  final String? excludeChannelId;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final type = ConcordTypography.of(context);
    final l10n = AppLocalizations.of(context);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: ConcordSpacing.xl),
        leading: ConcordAvatar(imageUrl: server.iconUrl, name: server.name, size: ConcordAvatarSize.sm),
        title: Text(server.name, style: TextStyle(fontSize: type.size(14), color: colors.fgDefault)),
        children: [
          Consumer(
            builder: (context, ref, _) {
              final channelsAsync = ref.watch(channelsProvider(server.id));
              return channelsAsync.when(
                data: (channels) {
                  final textChannels = channels
                      .where((c) => c.type == ChannelType.text && c.id != excludeChannelId)
                      .where((c) => query.isEmpty || c.name.toLowerCase().contains(query))
                      .toList();
                  if (textChannels.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
                      child: Text(l10n.noMatchingChannelsText, style: TextStyle(fontSize: type.size(12), color: colors.fgMuted)),
                    );
                  }
                  return Column(
                    children: [
                      for (final channel in textChannels)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.tag, size: 16, color: colors.fgMuted),
                          title: Text(channel.name, style: TextStyle(fontSize: type.size(13), color: colors.fgDefault)),
                          onTap: () => onPick(channel.id),
                        ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (error, stackTrace) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
                  child: Text(l10n.couldNotLoadChannelsPeriod, style: TextStyle(fontSize: type.size(12), color: colors.danger)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
