import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../providers/api_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

const _expiryOptions = <String, Duration?>{
  'Never': null,
  '30 minutes': Duration(minutes: 30),
  '1 hour': Duration(hours: 1),
  '1 day': Duration(days: 1),
  '7 days': Duration(days: 7),
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
  String _expiryLabel = 'Never';
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
    final rawMaxUses = _maxUsesController.text.trim();
    int? maxUses;
    if (rawMaxUses.isNotEmpty) {
      maxUses = int.tryParse(rawMaxUses);
      if (maxUses == null || maxUses <= 0) {
        setState(() => _error = 'Max uses must be a positive number.');
        return;
      }
    }

    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final duration = _expiryOptions[_expiryLabel];
      final invite = await ref.read(serversServiceProvider).createInvite(
            widget.serverId,
            expiresAtUtc: duration == null ? null : DateTime.now().toUtc().add(duration),
            maxUses: maxUses,
          );
      if (!mounted) return;
      setState(() => _invites = [invite, ...?_invites]);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message.isNotEmpty ? e.message : 'Could not generate an invite.');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite code copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;

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
            Text('Invite People', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: ConcordSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Expires', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 6),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _expiryLabel,
                        onChanged: _generating ? null : (v) => setState(() => _expiryLabel = v ?? 'Never'),
                        items: [
                          for (final label in _expiryOptions.keys) DropdownMenuItem(value: label, child: Text(label)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ConcordSpacing.md),
                Expanded(
                  child: ConcordTextField(
                    controller: _maxUsesController,
                    label: 'Max uses',
                    hint: 'Unlimited',
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
              label: 'Generate invite link',
              expand: true,
              loading: _generating,
              onPressed: _generating ? null : _generate,
            ),
            const SizedBox(height: ConcordSpacing.lg),
            Expanded(child: _buildInviteList(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteList(ConcordColors colors) {
    if (_loadingInvites) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: ConcordEmptyState(
          icon: Icons.error_outline,
          title: "Couldn't load invites",
          subtitle: _loadError,
          action: ConcordButton(
            label: 'Try again',
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
        child: Text('No invites generated yet.', style: TextStyle(color: colors.fgMuted)),
      );
    }
    return ListView.separated(
      itemCount: invites.length,
      separatorBuilder: (context, index) => const SizedBox(height: ConcordSpacing.sm),
      itemBuilder: (context, index) {
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
                        '${_describeUses(invite)} · ${_describeExpiry(invite, isExpired)}',
                        style: TextStyle(fontSize: 12, color: colors.fgMuted),
                      ),
                    ],
                  ),
                ),
                ConcordButton(
                  label: 'Copy',
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

  String _describeUses(InviteResponse invite) {
    if (invite.maxUses == null) return '${invite.useCount} use${invite.useCount == 1 ? '' : 's'}';
    final exhausted = invite.useCount >= invite.maxUses!;
    return '${invite.useCount} / ${invite.maxUses} uses${exhausted ? ' - exhausted' : ''}';
  }

  String _describeExpiry(InviteResponse invite, bool isExpired) {
    if (invite.expiresAtUtc == null) return 'Never expires';
    if (isExpired) return 'Expired';
    return 'Expires ${invite.expiresAtUtc!.toLocal()}';
  }
}
