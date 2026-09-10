import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../providers/draft_store.dart';
import '../../providers/message_thread_controller.dart';
import '../../providers/server_member_list_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

const _maxContentLength = 4000;
const _warnThreshold = _maxContentLength - 200;

const _maxMentionSuggestions = 5;

final _mentionTriggerRegex = RegExp(r'(?:^|\s)@([a-zA-Z0-9_]{0,32})$');

class _MentionTrigger {
  const _MentionTrigger({required this.startIndex, required this.query});

  final int startIndex;
  final String query;
}

const _acceptedExtensions = ['png', 'jpg', 'jpeg', 'webp', 'gif', 'mp4', 'mp3', 'ogg', 'pdf', 'txt', 'zip'];

const _extensionToContentType = {
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'webp': 'image/webp',
  'gif': 'image/gif',
  'mp4': 'video/mp4',
  'mp3': 'audio/mpeg',
  'ogg': 'audio/ogg',
  'pdf': 'application/pdf',
  'txt': 'text/plain',
  'zip': 'application/zip',
};

const _typingNotifyThrottle = Duration(seconds: 3);

enum _AttachmentStatus { uploading, ready }

class _PendingAttachment {
  const _PendingAttachment({required this.status, required this.filename, this.url});

  final _AttachmentStatus status;
  final String filename;
  final String? url;
}

class MessageComposer extends ConsumerStatefulWidget {
  const MessageComposer({
    super.key,
    required this.controller,
    required this.draftKey,
    required this.replyingTo,
    required this.onCancelReply,
    required this.onSent,
    this.hintText,
    this.serverId,
  });

  final MessageThreadController controller;

  final String draftKey;
  final MessageLike? replyingTo;
  final VoidCallback onCancelReply;
  final VoidCallback onSent;
  final String? hintText;

  final String? serverId;

  @override
  ConsumerState<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends ConsumerState<MessageComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _draftSaveTimer;
  DateTime? _lastTypingNotify;
  _PendingAttachment? _attachment;
  bool _isSending = false;
  bool _rateLimited = false;
  String? _sendError;
  _MentionTrigger? _mentionTrigger;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleContentChanged);
    unawaited(_restoreDraft());
  }

  Future<void> _restoreDraft() async {
    final draft = await DraftStore.read(widget.draftKey);
    if (!mounted || draft == null || draft.isEmpty) return;
    _controller.removeListener(_handleContentChanged);
    _controller.text = draft;
    _controller.addListener(_handleContentChanged);
    setState(() {});
  }

  void _handleContentChanged() {
    if (_rateLimited) setState(() => _rateLimited = false);
    if (_sendError != null) setState(() => _sendError = null);

    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 400), () {
      unawaited(DraftStore.save(widget.draftKey, _controller.text));
    });

    final trimmed = _controller.text.trim();
    if (trimmed.isNotEmpty) {
      final now = DateTime.now();
      if (_lastTypingNotify == null || now.difference(_lastTypingNotify!) > _typingNotifyThrottle) {
        _lastTypingNotify = now;
        unawaited(widget.controller.notifyTyping());
      }
    }
    _mentionTrigger = _detectMentionTrigger();
    setState(() {});
  }

  _MentionTrigger? _detectMentionTrigger() {
    if (widget.serverId == null) return null;
    final text = _controller.text;
    final selection = _controller.selection;
    var cursor = selection.isValid ? selection.baseOffset : text.length;
    if (cursor < 0) cursor = 0;
    if (cursor > text.length) cursor = text.length;

    final match = _mentionTriggerRegex.firstMatch(text.substring(0, cursor));
    if (match == null) return null;
    final query = match.group(1)!;
    return _MentionTrigger(startIndex: cursor - query.length - 1, query: query);
  }

  void _selectMention(ServerMemberSummary member) {
    final trigger = _mentionTrigger;
    final username = member.user.username;
    if (trigger == null || username == null || username.isEmpty) return;

    final text = _controller.text;
    final before = text.substring(0, trigger.startIndex);
    final afterStart = (trigger.startIndex + 1 + trigger.query.length).clamp(0, text.length).toInt();
    final after = text.substring(afterStart);
    final insertion = '@$username ';
    final newText = '$before$insertion$after';
    final newCursor = before.length + insertion.length;

    _controller.removeListener(_handleContentChanged);
    _controller.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newCursor));
    _controller.addListener(_handleContentChanged);
    unawaited(DraftStore.save(widget.draftKey, newText));
    setState(() => _mentionTrigger = null);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _draftSaveTimer?.cancel();
    _controller.removeListener(_handleContentChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: _acceptedExtensions);
    if (file == null) return;
    await _uploadAttachment(file: file);
  }

  Future<void> _uploadAttachment({required PlatformFile file}) async {
    final filename = file.name;
    setState(() => _attachment = _PendingAttachment(status: _AttachmentStatus.uploading, filename: filename));
    final extension = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    try {
      final bytes = await file.readAsBytes();
      final response = await ref.read(filesServiceProvider).uploadAttachment(
            bytes: bytes,
            filename: filename,
            contentType: _extensionToContentType[extension],
          );
      if (!mounted) return;
      setState(() => _attachment = _PendingAttachment(
            status: _AttachmentStatus.ready,
            filename: filename,
            url: response.url,
          ));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _attachment = null;
        _sendError = AppLocalizations.of(context).errorAttachFileFailed(e.message);
      });
    }
  }

  void _removeAttachment() {
    setState(() => _attachment = null);
  }

  bool get _canSend {
    final trimmedLength = _controller.text.trim().length;
    final overLimit = _controller.text.length > _maxContentLength;
    final hasReadyAttachment = _attachment?.status == _AttachmentStatus.ready;
    final isUploading = _attachment?.status == _AttachmentStatus.uploading;
    return (trimmedLength > 0 || hasReadyAttachment) && !overLimit && !isUploading && !_isSending;
  }

  Future<void> _handleSend() async {
    if (!_canSend) return;
    unawaited(HapticFeedback.lightImpact());
    final trimmed = _controller.text.trim();
    setState(() {
      _isSending = true;
      _sendError = null;
    });
    try {
      await widget.controller.sendMessage(
        content: trimmed,
        attachmentUrl: _attachment?.status == _AttachmentStatus.ready ? _attachment!.url : null,
        replyToMessageId: widget.replyingTo?.id,
      );
      if (!mounted) return;
      _controller.clear();
      await DraftStore.clear(widget.draftKey);
      setState(() {
        _attachment = null;
        _isSending = false;
      });
      widget.onCancelReply();
      widget.onSent();
      unawaited(widget.controller.stopTyping());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        if (e.isRateLimited) {
          _rateLimited = true;
        } else {
          _sendError = e.message;
        }
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter && !HardwareKeyboard.instance.isShiftPressed) {
      unawaited(_handleSend());
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape && widget.replyingTo != null) {
      widget.onCancelReply();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  List<ServerMemberSummary> _mentionCandidates() {
    final serverId = widget.serverId;
    final trigger = _mentionTrigger;
    if (serverId == null || trigger == null) return const [];
    final query = trigger.query.toLowerCase();
    final members = ref.watch(serverMemberListControllerProvider(serverId)).items;
    return members
        .where((m) => (m.user.username ?? '').toLowerCase().startsWith(query))
        .take(_maxMentionSuggestions)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);
    final overLimit = _controller.text.length > _maxContentLength;
    final mentionCandidates = _mentionCandidates();

    return Container(
      padding: const EdgeInsets.fromLTRB(ConcordSpacing.lg, ConcordSpacing.sm, ConcordSpacing.lg, ConcordSpacing.lg),
      decoration: BoxDecoration(color: colors.surfaceBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.replyingTo != null) _ReplyBanner(message: widget.replyingTo!, onCancel: widget.onCancelReply),
          if (_attachment != null) _AttachmentChip(attachment: _attachment!, onRemove: _removeAttachment),
          if (mentionCandidates.isNotEmpty)
            _MentionSuggestionsList(candidates: mentionCandidates, onSelect: _selectMention),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceSidebar,
              borderRadius: BorderRadius.circular(ConcordRadii.md),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file, size: 20, color: colors.fgMuted),
                  tooltip: l10n.attachFileTooltip,
                  onPressed: _isSending ? null : _pickAttachment,
                ),
                Expanded(
                  child: Focus(
                    onKeyEvent: _handleKeyEvent,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 6,
                      enabled: !_isSending,
                      textInputAction: TextInputAction.newline,
                      style: TextStyle(fontSize: 15, color: colors.fgDefault),
                      decoration: InputDecoration(
                        hintText: widget.hintText ?? l10n.messageChannelHint,
                        hintStyle: TextStyle(color: colors.fgMuted),
                        border: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: colors.brand),
                        )
                      : Icon(Icons.send, size: 20, color: _canSend ? colors.brand : colors.fgMuted),
                  tooltip: l10n.sendTooltip,
                  onPressed: _canSend ? _handleSend : null,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _rateLimited
                      ? Text(
                          l10n.rateLimitedMessage,
                          style: TextStyle(fontSize: 12, color: colors.warning),
                        )
                      : (_sendError != null
                          ? Text(_sendError!, style: TextStyle(fontSize: 12, color: colors.danger))
                          : (overLimit
                              ? Text(
                                  l10n.messageTooLong(_maxContentLength),
                                  style: TextStyle(fontSize: 12, color: colors.danger),
                                )
                              : const SizedBox.shrink())),
                ),
                if (_controller.text.length > _warnThreshold)
                  Text(
                    '${_controller.text.length}/$_maxContentLength',
                    style: TextStyle(fontSize: 12, color: overLimit ? colors.danger : colors.fgMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyBanner extends StatelessWidget {
  const _ReplyBanner({required this.message, required this.onCancel});

  final MessageLike message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);
    final senderName = displayNameFor(message.sender);

    return Container(
      margin: const EdgeInsets.only(bottom: ConcordSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceSidebar,
        borderRadius: BorderRadius.circular(ConcordRadii.md),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, size: 16, color: colors.fgMuted),
          const SizedBox(width: ConcordSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 13, color: colors.fgMuted),
                children: [
                  TextSpan(text: l10n.replyingToPrefix),
                  TextSpan(text: senderName, style: TextStyle(color: colors.fgDefault, fontWeight: FontWeight.w500)),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: colors.fgMuted),
            tooltip: l10n.cancelReplyTooltip,
            onPressed: onCancel,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({required this.attachment, required this.onRemove});

  final _PendingAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);
    final uploading = attachment.status == _AttachmentStatus.uploading;

    return Container(
      margin: const EdgeInsets.only(bottom: ConcordSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceSidebar,
        borderRadius: BorderRadius.circular(ConcordRadii.md),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        children: [
          if (uploading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.fgMuted),
            )
          else
            Icon(Icons.insert_drive_file_outlined, size: 16, color: colors.fgMuted),
          const SizedBox(width: ConcordSpacing.sm),
          Expanded(
            child: Text(
              attachment.filename,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: colors.fgDefault),
            ),
          ),
          Text(
            uploading ? l10n.uploadingEllipsis : l10n.readyToSendLabel,
            style: TextStyle(fontSize: 11, color: colors.fgMuted),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: colors.fgMuted),
            tooltip: l10n.removeAttachmentTooltip,
            onPressed: onRemove,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }
}

class _MentionSuggestionsList extends StatelessWidget {
  const _MentionSuggestionsList({required this.candidates, required this.onSelect});

  final List<ServerMemberSummary> candidates;
  final ValueChanged<ServerMemberSummary> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: ConcordSpacing.sm),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: colors.surfaceFloating,
        borderRadius: BorderRadius.circular(ConcordRadii.md),
        border: Border.all(color: colors.borderDefault),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: candidates.length,
        itemBuilder: (context, index) {
          final member = candidates[index];
          final name = displayNameFor(member.user);
          return InkWell(
            onTap: () => onSelect(member),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.sm),
              child: Row(
                children: [
                  ConcordAvatar(imageUrl: member.user.avatarUrl, name: name, size: ConcordAvatarSize.sm),
                  const SizedBox(width: ConcordSpacing.sm),
                  Expanded(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: colors.fgDefault),
                    ),
                  ),
                  if (member.user.username != null) ...[
                    const SizedBox(width: ConcordSpacing.sm),
                    Text('@${member.user.username}', style: TextStyle(fontSize: 11, color: colors.fgMuted)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
