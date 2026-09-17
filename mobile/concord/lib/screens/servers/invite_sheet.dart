import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

enum _ExpiryOption { never, thirtyMinutes, oneHour, oneDay, sevenDays }

const _expiryDurations = <_ExpiryOption, Duration?>{
  _ExpiryOption.never: null,
  _ExpiryOption.thirtyMinutes: Duration(minutes: 30),
  _ExpiryOption.oneHour: Duration(hours: 1),
  _ExpiryOption.oneDay: Duration(days: 1),
  _ExpiryOption.sevenDays: Duration(days: 7),
};

String _expiryLabelFor(AppLocalizations l10n, _ExpiryOption option) => switch (option) {
      _ExpiryOption.never => l10n.expiryNeverOption,
      _ExpiryOption.thirtyMinutes => l10n.expiryThirtyMinLabel,
      _ExpiryOption.oneHour => l10n.expiryOneHourLabel,
      _ExpiryOption.oneDay => l10n.expiryOneDayLabel,
      _ExpiryOption.sevenDays => l10n.expirySevenDaysLabel,
    };

Future<void> showInviteSheet(BuildContext context, WidgetRef ref, {required String serverId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _InviteSheet(serverId: serverId),
  );
}

class _InviteSheet extends ConsumerStatefulWidget {
  const _InviteSheet({required this.serverId});

  final String serverId;

  @override
  ConsumerState<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<_InviteSheet> {
  final _maxUsesController = TextEditingController();
  _ExpiryOption _expiry = _ExpiryOption.never;
  bool _generating = false;
  String? _error;

  List<InviteResponse>? _invites;
  bool _loadingInvites = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  @override
  void dispose() {
    _maxUsesController.dispose();
    super.dispose();
  }

  Future<void> _loadInvites() async {
    setState(() {
      _loadingInvites = true;
      _loadError = null;
    });
    try {
      final invites = await ref.read(serversServiceProvider).listInvites(widget.serverId);
      if (!mounted) return;
      setState(() {
        _invites = invites.reversed.toList();
        _loadingInvites = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loadingInvites = false;
      });
    }
  }

  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context);
    final rawMaxUses = _maxUsesController.text.trim();
    int? maxUses;
    if (rawMaxUses.isNotEmpty) {
      maxUses = int.tryParse(rawMaxUses);
      if (maxUses == null || maxUses <= 0) {
        setState(() => _error = l10n.maxUsesInvalidMessage);
        return;
      }
    }

    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final duration = _expiryDurations[_expiry];
      final invite = await ref.read(serversServiceProvider).createInvite(
            widget.serverId,
            expiresAtUtc: duration == null ? null : DateTime.now().toUtc().add(duration),
            maxUses: maxUses,
          );
      if (!mounted) return;
      setState(() => _invites = [invite, ...?_invites]);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message.isNotEmpty ? e.message : l10n.errorGenerateInviteFailed);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _copy(String code) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.inviteCodeCopiedSnackbar)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: ConcordSpacing.lg,
        right: ConcordSpacing.lg,
        top: ConcordSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + ConcordSpacing.lg,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.invitePeopleMenuItem, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: ConcordSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.expiresLabel, style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 6),
                      DropdownButton<_ExpiryOption>(
                        isExpanded: true,
                        value: _expiry,
                        onChanged: _generating ? null : (v) => setState(() => _expiry = v ?? _ExpiryOption.never),
                        items: [
                          for (final option in _ExpiryOption.values)
                            DropdownMenuItem(value: option, child: Text(_expiryLabelFor(l10n, option))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ConcordSpacing.md),
                Expanded(
                  child: ConcordTextField(
                    controller: _maxUsesController,
                    label: l10n.maxUsesLabel,
                    hint: l10n.unlimitedHint,
                    keyboardType: TextInputType.number,
                    enabled: !_generating,
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: ConcordSpacing.sm),
              Text(_error!, style: TextStyle(color: colors.danger)),
            ],
            const SizedBox(height: ConcordSpacing.md),
            ConcordButton(
              label: l10n.generateInviteLinkButton,
              expand: true,
              loading: _generating,
              onPressed: _generating ? null : _generate,
            ),
            const SizedBox(height: ConcordSpacing.lg),
            Expanded(child: _buildInviteList(colors, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteList(ConcordColors colors, AppLocalizations l10n) {
    if (_loadingInvites) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: ConcordEmptyState(
          icon: Icons.error_outline,
          title: l10n.couldNotLoadInvitesTitle,
          subtitle: _loadError,
          action: ConcordButton(
            label: l10n.tryAgainButton,
            variant: ConcordButtonVariant.secondary,
            size: ConcordButtonSize.sm,
            onPressed: _loadInvites,
          ),
        ),
      );
    }
    final invites = _invites ?? const [];
    if (invites.isEmpty) {
      return Center(
        child: Text(l10n.noInvitesYetText, style: TextStyle(color: colors.fgMuted)),
      );
    }
    return ListView.separated(
      itemCount: invites.length,
      separatorBuilder: (context, index) => const SizedBox(height: ConcordSpacing.sm),
      itemBuilder: (context, index) {
        final type = ConcordTypography.of(context);
        final invite = invites[index];
        final isExpired = invite.expiresAtUtc != null && invite.expiresAtUtc!.isBefore(DateTime.now().toUtc());
        final isExhausted = invite.maxUses != null && invite.useCount >= invite.maxUses!;
        final usable = !isExpired && !isExhausted;
        return Opacity(
          opacity: usable ? 1 : 0.6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surfaceSidebar,
              borderRadius: BorderRadius.circular(ConcordRadii.md),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invite.code,
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_describeUses(l10n, invite)} · ${_describeExpiry(l10n, invite, isExpired)}',
                        style: TextStyle(fontSize: type.size(12), color: colors.fgMuted),
                      ),
                    ],
                  ),
                ),
                ConcordButton(
                  label: l10n.copyButton,
                  variant: ConcordButtonVariant.secondary,
                  size: ConcordButtonSize.sm,
                  onPressed: usable ? () => _copy(invite.code) : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _describeUses(AppLocalizations l10n, InviteResponse invite) {
    if (invite.maxUses == null) return l10n.inviteUsesCount(invite.useCount);
    final exhausted = invite.useCount >= invite.maxUses!;
    return l10n.inviteUsesOfMax(invite.useCount, invite.maxUses!, exhausted ? l10n.inviteExhaustedSuffix : '');
  }

  String _describeExpiry(AppLocalizations l10n, InviteResponse invite, bool isExpired) {
    if (invite.expiresAtUtc == null) return l10n.neverExpiresLabel;
    if (isExpired) return l10n.expiredLabel;
    return l10n.expiresOnLabel('${invite.expiresAtUtc!.toLocal()}');
  }
}
