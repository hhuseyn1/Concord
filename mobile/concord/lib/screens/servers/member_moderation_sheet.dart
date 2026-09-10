import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../providers/server_member_list_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

Map<int, String> _timeoutPresets(AppLocalizations l10n) => {
      5: l10n.timeoutFiveMin,
      60: l10n.expiryOneHourLabel,
      24 * 60: l10n.expiryOneDayLabel,
      7 * 24 * 60: l10n.expirySevenDaysLabel,
    };

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

  void _showErrorNow(AppLocalizations l10n, String action, ApiException e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.errorModerationFailed(action, e.message.isNotEmpty ? e.message : l10n.unknownErrorLabel))),
    );
  }

  void _showErrorLater(AppLocalizations l10n, String action, ApiException e) {
    final rootContext = widget.rootContext;
    if (!rootContext.mounted) return;
    ScaffoldMessenger.of(rootContext).showSnackBar(
      SnackBar(content: Text(l10n.errorModerationFailed(action, e.message.isNotEmpty ? e.message : l10n.unknownErrorLabel))),
    );
  }

  Future<void> _toggleMute() async {
    final l10n = AppLocalizations.of(context);
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
      _showErrorNow(l10n, wasMuted ? l10n.actionUnmuteMember : l10n.actionMuteMember, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeTimeout() async {
    final l10n = AppLocalizations.of(context);
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
      _showErrorNow(l10n, l10n.actionRemoveTimeout, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openTimeoutSheet() async {
    final l10n = AppLocalizations.of(context);
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
      _showErrorLater(l10n, l10n.actionTimeoutMember, e);
    }
  }

  Future<void> _confirmKick() async {
    final l10n = AppLocalizations.of(context);
    Navigator.of(context).pop();
    final rootContext = widget.rootContext;
    if (!rootContext.mounted) return;
    final confirmed = await showDialog<bool>(
      context: rootContext,
      builder: (context) => AlertDialog(
        title: Text(l10n.kickConfirmTitle(_displayName)),
        content: Text(l10n.kickConfirmMessage(_displayName)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancelButton)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.kickAction)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final userId = widget.member.user.id;
      await widget.ref.read(serversServiceProvider).kickMember(widget.serverId, userId);
      _remove((m) => m.user.id == userId);
    } on ApiException catch (e) {
      _showErrorLater(l10n, l10n.actionKickMember, e);
    }
  }

  Future<void> _openBanSheet() async {
    final l10n = AppLocalizations.of(context);
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
      _showErrorLater(l10n, l10n.actionBanMember, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);
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
              title: Text(isMuted ? l10n.unmuteAction : l10n.muteAction),
              enabled: !_busy,
              onTap: _busy ? null : _toggleMute,
            ),
          if (permissions.hasModerateMembers)
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: Text(isTimedOut ? l10n.removeTimeoutAction : l10n.timeoutAction),
              enabled: !_busy,
              onTap: _busy ? null : (isTimedOut ? _removeTimeout : _openTimeoutSheet),
            ),
          if (permissions.hasKickMembers || permissions.hasBanMembers) const Divider(height: 1),
          if (permissions.hasKickMembers)
            ListTile(
              leading: Icon(Icons.person_remove_outlined, color: colors.danger),
              title: Text(l10n.kickAction, style: TextStyle(color: colors.danger)),
              enabled: !_busy,
              onTap: _busy ? null : _confirmKick,
            ),
          if (permissions.hasBanMembers)
            ListTile(
              leading: Icon(Icons.block, color: colors.danger),
              title: Text(l10n.banAction, style: TextStyle(color: colors.danger)),
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
    final l10n = AppLocalizations.of(context);
    final timeoutPresets = _timeoutPresets(l10n);
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
          Text(l10n.timeoutConfirmTitle(widget.displayName), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.timeoutConfirmMessage,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ConcordSpacing.lg),
          Text(l10n.durationLabel, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: ConcordSpacing.sm),
          Wrap(
            spacing: ConcordSpacing.sm,
            runSpacing: ConcordSpacing.sm,
            children: [
              for (final entry in timeoutPresets.entries)
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
            label: l10n.reasonLabel,
            hint: l10n.optionalHint,
          ),
          const SizedBox(height: ConcordSpacing.lg),
          Row(
            children: [
              const Spacer(),
              ConcordButton(
                label: l10n.cancelButton,
                variant: ConcordButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: ConcordSpacing.sm),
              ConcordButton(
                label: l10n.timeoutAction,
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
    final l10n = AppLocalizations.of(context);
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
          Text(l10n.banConfirmTitle(widget.displayName), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.banConfirmMessage,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ConcordSpacing.lg),
          ConcordTextField(controller: _reasonController, label: l10n.reasonLabel, hint: l10n.optionalHint),
          const SizedBox(height: ConcordSpacing.lg),
          Row(
            children: [
              const Spacer(),
              ConcordButton(
                label: l10n.cancelButton,
                variant: ConcordButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: ConcordSpacing.sm),
              ConcordButton(
                label: l10n.banAction,
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
