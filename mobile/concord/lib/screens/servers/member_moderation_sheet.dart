import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../providers/api_providers.dart';
import '../../providers/server_member_list_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

/// Offered timeout lengths, in minutes — mirrors the presets the web app's `MemberModerationMenu`
/// exposes (which itself mirrors Discord's).
const _timeoutPresets = <int, String>{
  5: '5 minutes',
  60: '1 hour',
  24 * 60: '1 day',
  7 * 24 * 60: '7 days',
};

/// Per-member moderation sheet (P1): mute, timeout, kick, ban — mirrors the web app's
/// `MemberModerationMenu`. Visibility is per-action: each item only appears if the caller holds
/// that specific permission (`MuteMembers`/`ModerateMembers`/`KickMembers`/`BanMembers`).
///
/// The hierarchy rule (an actor cannot act on the owner, on themselves, or on anyone ranked at or
/// above them) is enforced server-side by `PermissionService.AssertCanActOnMemberAsync`. This sheet
/// only re-derives the two cases it can know cheaply — self and owner — to hide the entry point
/// outright (see the caller in `ServerMemberRow`); rank is deliberately not re-derived here, so
/// anything that slips through simply comes back as a 403 surfaced via a snackbar.
///
/// Takes `ref` from the caller (the member row) rather than watching providers itself: several
/// actions here (timeout, kick, ban) close this sheet before their follow-up dialog/mutation runs,
/// which would tear down a `ConsumerState`-owned `ref` mid-flight. The row's `ref`/`context` outlive
/// that, since kicking/banning *this* member doesn't unmount the row list itself mid-callback.
Future<void> showMemberModerationSheet(
  BuildContext context,
  WidgetRef ref, {
  required String serverId,
  required ServerMemberSummary member,
  required MyServerPermissionsResponse permissions,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _MemberModerationSheet(
      rootContext: context,
      ref: ref,
      serverId: serverId,
      member: member,
      permissions: permissions,
    ),
  );
}

class _MemberModerationSheet extends StatefulWidget {
  const _MemberModerationSheet({
    required this.rootContext,
    required this.ref,
    required this.serverId,
    required this.member,
    required this.permissions,
  });

  /// The context that opened this sheet (the member row) — used for any follow-up
  /// dialog/sheet/snackbar shown *after* this sheet pops, since this widget's own `context`
  /// becomes unmounted the moment its route is popped.
  final BuildContext rootContext;
  final WidgetRef ref;
  final String serverId;
  final ServerMemberSummary member;
  final MyServerPermissionsResponse permissions;

  @override
  State<_MemberModerationSheet> createState() => _MemberModerationSheetState();
}

class _MemberModerationSheetState extends State<_MemberModerationSheet> {
  bool _busy = false;

  String get _displayName => displayNameFor(widget.member.user);

  void _patch(bool Function(ServerMemberSummary) match, ServerMemberSummary Function(ServerMemberSummary) update) {
    widget.ref.read(serverMemberListControllerProvider(widget.serverId).notifier).patchWhere(match, update);
  }

  void _remove(bool Function(ServerMemberSummary) match) {
    widget.ref.read(serverMemberListControllerProvider(widget.serverId).notifier).removeWhere(match);
  }

  void _showErrorNow(String action, ApiException e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not $action: ${e.message.isNotEmpty ? e.message : 'unknown error'}')),
    );
  }

  void _showErrorLater(String action, ApiException e) {
    final rootContext = widget.rootContext;
    if (!rootContext.mounted) return;
    ScaffoldMessenger.of(rootContext).showSnackBar(
      SnackBar(content: Text('Could not $action: ${e.message.isNotEmpty ? e.message : 'unknown error'}')),
    );
  }

  Future<void> _toggleMute() async {
    final userId = widget.member.user.id;
    final wasMuted = widget.member.isMuted;
    setState(() => _busy = true);
    try {
      final service = widget.ref.read(moderationServiceProvider);
      final result = wasMuted
          ? await service.unmuteMember(widget.serverId, userId)
          : await service.muteMember(widget.serverId, userId);
      _patch((m) => m.user.id == userId, (m) => m.copyWith(isMuted: result.isMuted));
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      _showErrorNow(wasMuted ? 'unmute this member' : 'mute this member', e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeTimeout() async {
    final userId = widget.member.user.id;
    setState(() => _busy = true);
    try {
      final result = await widget.ref.read(moderationServiceProvider).removeTimeout(widget.serverId, userId);
      _patch(
        (m) => m.user.id == userId,
        (m) => m.copyWith(timedOutUntil: result.timedOutUntil, clearTimedOutUntil: result.timedOutUntil == null),
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      _showErrorNow('remove this timeout', e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openTimeoutSheet() async {
    Navigator.of(context).pop();
    final rootContext = widget.rootContext;
    if (!rootContext.mounted) return;
    final result = await showModalBottomSheet<_TimeoutChoice>(
      context: rootContext,
      isScrollControlled: true,
      builder: (context) => _TimeoutSheet(displayName: _displayName),
    );
    if (result == null) return;
    try {
      final userId = widget.member.user.id;
      final response = await widget.ref.read(moderationServiceProvider).timeoutMember(
            widget.serverId,
            userId,
            durationMinutes: result.durationMinutes,
            reason: result.reason,
          );
      _patch((m) => m.user.id == userId, (m) => m.copyWith(timedOutUntil: response.timedOutUntil));
    } on ApiException catch (e) {
      _showErrorLater('time out this member', e);
    }
  }

  Future<void> _confirmKick() async {
    Navigator.of(context).pop();
    final rootContext = widget.rootContext;
    if (!rootContext.mounted) return;
    final confirmed = await showDialog<bool>(
      context: rootContext,
      builder: (context) => AlertDialog(
        title: Text('Kick $_displayName?'),
        content: Text('$_displayName will be removed from the server. They can rejoin with a valid invite.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Kick')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final userId = widget.member.user.id;
      await widget.ref.read(serversServiceProvider).kickMember(widget.serverId, userId);
      _remove((m) => m.user.id == userId);
    } on ApiException catch (e) {
      _showErrorLater('kick this member', e);
    }
  }

  Future<void> _openBanSheet() async {
    Navigator.of(context).pop();
    final rootContext = widget.rootContext;
    if (!rootContext.mounted) return;
    final result = await showModalBottomSheet<String>(
      context: rootContext,
      isScrollControlled: true,
      builder: (context) => _BanSheet(displayName: _displayName),
    );
    if (result == null) return;
    try {
      final userId = widget.member.user.id;
      await widget.ref
          .read(moderationServiceProvider)
          .banMember(widget.serverId, userId, reason: result.isEmpty ? null : result);
      _remove((m) => m.user.id == userId);
    } on ApiException catch (e) {
      _showErrorLater('ban this member', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final permissions = widget.permissions;
    final isMuted = widget.member.isMuted;
    final isTimedOut = widget.member.isTimedOut;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(ConcordSpacing.md),
            child: Text(_displayName, style: Theme.of(context).textTheme.titleMedium),
          ),
          const Divider(height: 1),
          if (permissions.hasMuteMembers)
            ListTile(
              leading: Icon(isMuted ? Icons.volume_up_outlined : Icons.mic_off_outlined),
              title: Text(isMuted ? 'Unmute' : 'Mute'),
              enabled: !_busy,
              onTap: _busy ? null : _toggleMute,
            ),
          if (permissions.hasModerateMembers)
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: Text(isTimedOut ? 'Remove Timeout' : 'Timeout'),
              enabled: !_busy,
              onTap: _busy ? null : (isTimedOut ? _removeTimeout : _openTimeoutSheet),
            ),
          if (permissions.hasKickMembers || permissions.hasBanMembers) const Divider(height: 1),
          if (permissions.hasKickMembers)
            ListTile(
              leading: Icon(Icons.person_remove_outlined, color: colors.danger),
              title: Text('Kick', style: TextStyle(color: colors.danger)),
              enabled: !_busy,
              onTap: _busy ? null : _confirmKick,
            ),
          if (permissions.hasBanMembers)
            ListTile(
              leading: Icon(Icons.block, color: colors.danger),
              title: Text('Ban', style: TextStyle(color: colors.danger)),
              enabled: !_busy,
              onTap: _busy ? null : _openBanSheet,
            ),
        ],
      ),
    );
  }
}

class _TimeoutChoice {
  const _TimeoutChoice(this.durationMinutes, this.reason);

  final int durationMinutes;
  final String? reason;
}

class _TimeoutSheet extends StatefulWidget {
  const _TimeoutSheet({required this.displayName});

  final String displayName;

  @override
  State<_TimeoutSheet> createState() => _TimeoutSheetState();
}

class _TimeoutSheetState extends State<_TimeoutSheet> {
  final _reasonController = TextEditingController();
  int _durationMinutes = 60;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: ConcordSpacing.lg,
        right: ConcordSpacing.lg,
        top: ConcordSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + ConcordSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Time out ${widget.displayName}?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            "They'll temporarily lose the ability to send messages and speak in voice channels.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ConcordSpacing.lg),
          Text('Duration', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: ConcordSpacing.sm),
          Wrap(
            spacing: ConcordSpacing.sm,
            runSpacing: ConcordSpacing.sm,
            children: [
              for (final entry in _timeoutPresets.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _durationMinutes == entry.key,
                  onSelected: (_) => setState(() => _durationMinutes = entry.key),
                ),
            ],
          ),
          const SizedBox(height: ConcordSpacing.lg),
          ConcordTextField(
            controller: _reasonController,
            label: 'Reason',
            hint: 'Optional',
          ),
          const SizedBox(height: ConcordSpacing.lg),
          Row(
            children: [
              const Spacer(),
              ConcordButton(
                label: 'Cancel',
                variant: ConcordButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: ConcordSpacing.sm),
              ConcordButton(
                label: 'Timeout',
                onPressed: () => Navigator.of(context).pop(
                  _TimeoutChoice(
                    _durationMinutes,
                    _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BanSheet extends StatefulWidget {
  const _BanSheet({required this.displayName});

  final String displayName;

  @override
  State<_BanSheet> createState() => _BanSheetState();
}

class _BanSheetState extends State<_BanSheet> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: ConcordSpacing.lg,
        right: ConcordSpacing.lg,
        top: ConcordSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + ConcordSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ban ${widget.displayName}?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            "This removes them from the server and blocks them from rejoining through any invite.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ConcordSpacing.lg),
          ConcordTextField(controller: _reasonController, label: 'Reason', hint: 'Optional'),
          const SizedBox(height: ConcordSpacing.lg),
          Row(
            children: [
              const Spacer(),
              ConcordButton(
                label: 'Cancel',
                variant: ConcordButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: ConcordSpacing.sm),
              ConcordButton(
                label: 'Ban',
                variant: ConcordButtonVariant.danger,
                onPressed: () => Navigator.of(context).pop(_reasonController.text.trim()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
