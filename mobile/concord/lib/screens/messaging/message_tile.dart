import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/message_thread_controller.dart';
import '../../providers/server_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/theme.dart';
import '../../utils/message_time_format.dart';
import '../../widgets/widgets.dart';
import 'forward_message_sheet.dart';
import 'message_attachment_view.dart';

const _quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🎉'];
const _maxContentLength = 4000;
const _replyPreviewMaxLength = 80;

class MessageTile extends ConsumerStatefulWidget {
  const MessageTile({
    super.key,
    required this.message,
    required this.showHeader,
    required this.isOwn,
    required this.currentUserId,
    required this.replyToMessage,
    required this.controller,
    required this.onReply,
    this.threadNoun = 'channel',
    this.serverId,
    this.sourceChannelId,
    this.sourceConversationId,
  });

  final MessageLike message;
  final bool showHeader;
  final bool isOwn;
  final String? currentUserId;

  final String? serverId;

  final String? sourceChannelId;
  final String? sourceConversationId;

  final MessageLike? replyToMessage;
  final MessageThreadController controller;
  final ValueChanged<MessageLike> onReply;

  final String threadNoun;

  @override
  ConsumerState<MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends ConsumerState<MessageTile> {
  bool _isEditing = false;
  late TextEditingController _editController;
  String? _editError;
  bool _isSavingEdit = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message.content ?? '');
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  MessageThreadController get _controller => widget.controller;

  bool _computeCanDeleteForEveryone() {
    if (widget.isOwn) return true;
    final serverId = widget.serverId;
    if (serverId == null) return false;
    final permissions = ref.watch(myPermissionsProvider(serverId));
    return permissions.maybeWhen(data: (p) => p.hasManageMessages, orElse: () => false);
  }

  bool _canDeleteForEveryone = false;

  void _startEdit() {
    setState(() {
      _editController.text = widget.message.content ?? '';
      _editError = null;
      _isEditing = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _editError = null;
    });
  }

  Future<void> _saveEdit() async {
    final l10n = AppLocalizations.of(context);
    final trimmed = _editController.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _editError = l10n.messageCannotBeEmpty);
      return;
    }
    if (trimmed.length > _maxContentLength) {
      setState(() => _editError = l10n.messageTooLongChars(_maxContentLength));
      return;
    }
    if (trimmed == widget.message.content) {
      setState(() => _isEditing = false);
      return;
    }
    setState(() => _isSavingEdit = true);
    try {
      await _controller.editMessage(widget.message.id, trimmed);
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _isSavingEdit = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSavingEdit = false;
        _editError = e.message;
      });
    }
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: widget.message.content ?? ''));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).copiedToClipboard)));
  }

  Future<void> _togglePin() async {
    try {
      if (widget.message.pinnedAt != null) {
        await _controller.unpinMessage(widget.message.id);
      } else {
        await _controller.pinMessage(widget.message.id);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).errorUpdatePinFailed(e.message))));
    }
  }

  Future<void> _toggleReaction(String emoji) async {
    unawaited(HapticFeedback.selectionClick());
    try {
      await _controller.toggleReaction(widget.message.id, emoji);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).errorReactFailed(e.message))));
    }
  }

  Future<void> _handleDelete() async {
    final l10n = AppLocalizations.of(context);
    final canDeleteForEveryone = _canDeleteForEveryone;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(canDeleteForEveryone ? l10n.deleteMessageConfirmTitle : l10n.hideMessageConfirmTitle),
        content: Text(
          canDeleteForEveryone
              ? l10n.deleteMessageConfirmMessage(widget.threadNoun)
              : l10n.hideMessageConfirmMessage,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancelButton)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(canDeleteForEveryone ? l10n.deleteMessageButton : l10n.hideMessageButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final deletedForEveryone = await _controller.deleteMessage(widget.message.id);
      if (mounted && deletedForEveryone != canDeleteForEveryone) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deletedForEveryone
                  ? l10n.deletedForEveryoneNotice(widget.threadNoun)
                  : l10n.hiddenOnlyForYouNotice,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorRemoveMessageFailed(e.message))));
    }
  }

  Future<void> _openForwardSheet() async {
    await showForwardMessageSheet(
      context,
      message: widget.message,
      controller: _controller,
      sourceChannelId: widget.sourceChannelId,
      sourceConversationId: widget.sourceConversationId,
    );
  }

  Future<void> _openActionSheet() async {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surfaceFloating,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ConcordRadii.lg)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final emoji in _quickReactions)
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(ConcordRadii.md),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _toggleReaction(emoji);
                          },
                          child: Center(
                            child: Text(emoji, style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.reply),
                title: Text(l10n.replyAction),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  widget.onReply(widget.message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.forward),
                title: Text(l10n.forwardAction),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openForwardSheet();
                },
              ),
              if (widget.isOwn)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.editMessageAction),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _startEdit();
                  },
                ),
              if (widget.message.content != null && widget.message.content!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.copy_outlined),
                  title: Text(l10n.copyTextAction),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _copyText();
                  },
                ),
              ListTile(
                leading: Icon(widget.message.pinnedAt != null ? Icons.push_pin : Icons.push_pin_outlined),
                title: Text(widget.message.pinnedAt != null ? l10n.unpinAction : l10n.pinAction),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _togglePin();
                },
              ),
              ListTile(
                leading: Icon(
                  _canDeleteForEveryone ? Icons.delete_outline : Icons.visibility_off_outlined,
                  color: colors.danger,
                ),
                title: Text(
                  _canDeleteForEveryone ? l10n.deleteMessageButton : l10n.hideForMeAction,
                  style: TextStyle(color: colors.danger),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _handleDelete();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final type = ConcordTypography.of(context);
    final l10n = AppLocalizations.of(context);
    final message = widget.message;
    final sender = message.sender;
    final senderName = displayNameFor(sender);
    _canDeleteForEveryone = _computeCanDeleteForEveryone();

    return InkWell(
      onLongPress: _openActionSheet,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          ConcordSpacing.lg,
          widget.showHeader ? ConcordSpacing.md : 2,
          ConcordSpacing.lg,
          2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: widget.showHeader
                  ? ConcordAvatar(imageUrl: sender.avatarUrl, name: senderName, size: ConcordAvatarSize.md)
                  : Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        formatShortTime(l10n, message.created),
                        style: TextStyle(fontSize: type.size(10), color: colors.fgMuted),
                      ),
                    ),
            ),
            const SizedBox(width: ConcordSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showHeader)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            senderName,
                            style: TextStyle(fontSize: type.size(14), fontWeight: FontWeight.w600, color: colors.fgDefault),
                          ),
                          const SizedBox(width: ConcordSpacing.sm),
                          Tooltip(
                            message: formatAbsoluteTimestamp(message.created),
                            child: Text(
                              formatGroupTimestamp(l10n, message.created),
                              style: TextStyle(fontSize: type.size(11), color: colors.fgMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (message.forwardedFromSenderId != null) _ForwardedFromLine(userId: message.forwardedFromSenderId!),
                  if (message.replyToMessageId != null) _ReplyQuote(replyTo: widget.replyToMessage),
                  if (_isEditing) _buildEditor(colors) else _buildContent(colors),
                  MessageAttachmentView(url: message.attachmentUrl),
                  if (message.reactions.isNotEmpty) _buildReactions(colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ConcordColors colors) {
    final type = ConcordTypography.of(context);
    final content = widget.message.content;
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: type.size(14), color: colors.fgDefault, height: 1.35),
        children: [
          ..._buildContentSpans(content, colors),
          if (widget.message.editedAtUtc != null)
            TextSpan(
              text: AppLocalizations.of(context).editedSuffix,
              style: TextStyle(fontSize: type.size(10), color: colors.fgMuted),
            ),
        ],
      ),
    );
  }

  Map<String, PublicProfileResponse> _resolveMentionedUsers() {
    if (widget.message.mentionedUserIds.isEmpty) return const {};
    final byUsername = <String, PublicProfileResponse>{};
    for (final userId in widget.message.mentionedUserIds) {
      final profile = ref.watch(userProfileProvider(userId)).valueOrNull;
      final username = profile?.username;
      if (profile != null && username != null && username.isNotEmpty) {
        byUsername[username.toLowerCase()] = profile;
      }
    }
    return byUsername;
  }

  List<InlineSpan> _buildContentSpans(String content, ConcordColors colors) {
    final mentionedUsers = _resolveMentionedUsers();
    if (mentionedUsers.isEmpty) return [TextSpan(text: content)];

    final regex = RegExp(r'@([a-zA-Z0-9_]{1,32})');
    final spans = <InlineSpan>[];
    var lastEnd = 0;
    for (final match in regex.allMatches(content)) {
      final username = match.group(1)!;
      if (!mentionedUsers.containsKey(username.toLowerCase())) continue;
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: content.substring(lastEnd, match.start)));
      }
      spans.add(
        TextSpan(
          text: '@$username',
          style: TextStyle(
            color: colors.brand,
            fontWeight: FontWeight.w600,
            backgroundColor: colors.brandBg,
          ),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < content.length) {
      spans.add(TextSpan(text: content.substring(lastEnd)));
    }
    return spans;
  }

  Widget _buildEditor(ConcordColors colors) {
    final type = ConcordTypography.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _editController,
            autofocus: true,
            minLines: 1,
            maxLines: 6,
            enabled: !_isSavingEdit,
            style: TextStyle(fontSize: type.size(14), color: colors.fgDefault),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: colors.surfaceInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ConcordRadii.sm),
                borderSide: BorderSide(color: _editError != null ? colors.danger : colors.borderDefault),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          ),
          if (_editError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_editError!, style: TextStyle(fontSize: type.size(11), color: colors.danger)),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                TextButton(
                  onPressed: _isSavingEdit ? null : _saveEdit,
                  child: Text(l10n.saveButton),
                ),
                TextButton(
                  onPressed: _isSavingEdit ? null : _cancelEdit,
                  child: Text(l10n.cancelButton),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactions(ConcordColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final reaction in widget.message.reactions)
            _ReactionPill(
              emoji: reaction.emoji,
              count: reaction.userIds.length,
              reactedByMe: widget.currentUserId != null && reaction.userIds.contains(widget.currentUserId),
              onTap: () => _toggleReaction(reaction.emoji),
            ),
        ],
      ),
    );
  }
}

class _ReactionPill extends StatelessWidget {
  const _ReactionPill({
    required this.emoji,
    required this.count,
    required this.reactedByMe,
    required this.onTap,
  });

  final String emoji;
  final int count;
  final bool reactedByMe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final type = ConcordTypography.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ConcordRadii.full),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: reactedByMe ? colors.brandBg : colors.surfaceSidebar,
              borderRadius: BorderRadius.circular(ConcordRadii.full),
              border: Border.all(color: reactedByMe ? colors.brand : colors.borderDefault),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: TextStyle(fontSize: type.size(13))),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: type.size(12),
                    fontWeight: FontWeight.w500,
                    color: reactedByMe ? colors.brand : colors.fgMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({required this.replyTo});

  final MessageLike? replyTo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final type = ConcordTypography.of(context);
    final l10n = AppLocalizations.of(context);
    if (replyTo == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Icon(Icons.subdirectory_arrow_right, size: 14, color: colors.fgMuted),
            const SizedBox(width: 4),
            Text(
              l10n.originalMessageLabel,
              style: TextStyle(fontSize: type.size(12), fontStyle: FontStyle.italic, color: colors.fgMuted),
            ),
          ],
        ),
      );
    }
    final senderName = displayNameFor(replyTo!.sender);
    final content = replyTo!.content;
    final preview = content == null || content.isEmpty
        ? l10n.attachmentLabel
        : (content.length > _replyPreviewMaxLength ? '${content.substring(0, _replyPreviewMaxLength)}…' : content);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_right, size: 14, color: colors.fgMuted),
          const SizedBox(width: 4),
          Text(senderName, style: TextStyle(fontSize: type.size(12), fontWeight: FontWeight.w500, color: colors.fgMuted)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              preview,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: type.size(12), color: colors.fgMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForwardedFromLine extends ConsumerWidget {
  const _ForwardedFromLine({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final type = ConcordTypography.of(context);
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(userProfileProvider(userId));
    final name = profileAsync.maybeWhen(data: (profile) => displayNameFor(profile), orElse: () => l10n.someoneFallbackLower);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(Icons.forward, size: 12, color: colors.fgMuted),
          const SizedBox(width: 4),
          Text(l10n.forwardedFromLabel(name), style: TextStyle(fontSize: type.size(11), color: colors.fgMuted)),
        ],
      ),
    );
  }
}
