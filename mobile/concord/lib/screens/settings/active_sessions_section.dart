import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

const _mobileOsHints = ['ios', 'android'];

class ActiveSessionsSection extends ConsumerWidget {
  const ActiveSessionsSection({super.key});

  Future<void> _confirmRevoke(BuildContext context, WidgetRef ref, String sessionId, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out this device?'),
        content: Text('$label will be signed out immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await ref.read(sessionsControllerProvider.notifier).revoke(sessionId);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not sign out that device: $error')));
    }
  }

  Future<void> _confirmRevokeAllOthers(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out all other devices?'),
        content: const Text('Every other device signed into your account will be signed out immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sign out others')),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await ref.read(sessionsControllerProvider.notifier).revokeAllOthers();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not sign out other devices: $error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(sessionsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Active Sessions', style: textTheme.titleMedium),
            if (state.items.where((s) => !s.isCurrent).isNotEmpty)
              ConcordButton(
                label: 'Sign out others',
                variant: ConcordButtonVariant.secondary,
                size: ConcordButtonSize.sm,
                loading: state.revokingId == revokeAllOthersMarker,
                onPressed:
                    state.revokingId != null ? null : () => _confirmRevokeAllOthers(context, ref),
              ),
          ],
        ),
        const SizedBox(height: ConcordSpacing.md),
        if (state.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (state.loadError != null)
          ConcordEmptyState(
            icon: Icons.error_outline,
            title: "Couldn't load your sessions",
            subtitle: state.loadError,
            compact: true,
            action: ConcordButton(
              label: 'Try again',
              variant: ConcordButtonVariant.secondary,
              size: ConcordButtonSize.sm,
              onPressed: () => ref.read(sessionsControllerProvider.notifier).load(),
            ),
          )
        else
          for (final session in state.items)
            Padding(
              padding: const EdgeInsets.only(bottom: ConcordSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(ConcordSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.borderSubtle),
                  borderRadius: BorderRadius.circular(ConcordRadii.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      _mobileOsHints.any((hint) => (session.os ?? '').toLowerCase().contains(hint))
                          ? Icons.smartphone
                          : Icons.laptop,
                      color: colors.fgMuted,
                    ),
                    const SizedBox(width: ConcordSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  session.deviceLabel?.isNotEmpty == true ? session.deviceLabel! : 'Unknown device',
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                              if (session.isCurrent) ...[
                                const SizedBox(width: ConcordSpacing.xs),
                                ConcordBadge(label: 'This device', variant: ConcordBadgeVariant.brand),
                              ],
                            ],
                          ),
                          Text(
                            'Last active ${_relativeTime(session.lastActiveAt)}'
                            '${session.ipAddress != null ? ' · ${session.ipAddress}' : ''}',
                            style: textTheme.bodySmall?.copyWith(color: colors.fgMuted),
                          ),
                        ],
                      ),
                    ),
                    if (!session.isCurrent)
                      ConcordIconButton(
                        icon: Icons.logout,
                        tooltip: 'Sign out this device',
                        onPressed: state.revokingId != null
                            ? null
                            : () => _confirmRevoke(
                                  context,
                                  ref,
                                  session.id,
                                  session.deviceLabel?.isNotEmpty == true ? session.deviceLabel! : 'This device',
                                ),
                      ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

String _relativeTime(DateTime utc) {
  final diff = DateTime.now().difference(utc.toLocal());
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
