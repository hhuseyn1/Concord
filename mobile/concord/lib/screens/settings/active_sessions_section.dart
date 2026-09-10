import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/settings_providers.dart';
import '../../theme/theme.dart';
import '../../utils/message_time_format.dart';
import '../../widgets/widgets.dart';

const _mobileOsHints = ['ios', 'android'];

class ActiveSessionsSection extends ConsumerWidget {
  const ActiveSessionsSection({super.key});

  Future<void> _confirmRevoke(BuildContext context, WidgetRef ref, String sessionId, String label) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOutDeviceConfirmTitle),
        content: Text(l10n.signOutDeviceConfirmMessage(label)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancelButton)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.signOutButton)),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await ref.read(sessionsControllerProvider.notifier).revoke(sessionId);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorSignOutDeviceFailed(error))));
    }
  }

  Future<void> _confirmRevokeAllOthers(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOutAllOthersConfirmTitle),
        content: Text(l10n.signOutAllOthersConfirmMessage),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancelButton)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.signOutOthersButton)),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await ref.read(sessionsControllerProvider.notifier).revokeAllOthers();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorSignOutOthersFailed(error))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(sessionsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.activeSessionsTitle, style: textTheme.titleMedium),
            if (state.items.where((s) => !s.isCurrent).isNotEmpty)
              ConcordButton(
                label: l10n.signOutOthersButton,
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
            title: l10n.couldNotLoadSessionsTitle,
            subtitle: state.loadError,
            compact: true,
            action: ConcordButton(
              label: l10n.tryAgainButton,
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
                                  session.deviceLabel?.isNotEmpty == true ? session.deviceLabel! : l10n.unknownDeviceLabel,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                              if (session.isCurrent) ...[
                                const SizedBox(width: ConcordSpacing.xs),
                                ConcordBadge(label: l10n.thisDeviceBadge, variant: ConcordBadgeVariant.brand),
                              ],
                            ],
                          ),
                          Text(
                            l10n.lastActiveLabel(formatRelativeTime(l10n, session.lastActiveAt)) +
                                (session.ipAddress != null ? ' · ${session.ipAddress}' : ''),
                            style: textTheme.bodySmall?.copyWith(color: colors.fgMuted),
                          ),
                        ],
                      ),
                    ),
                    if (!session.isCurrent)
                      ConcordIconButton(
                        icon: Icons.logout,
                        tooltip: l10n.signOutDeviceTooltip,
                        onPressed: state.revokingId != null
                            ? null
                            : () => _confirmRevoke(
                                  context,
                                  ref,
                                  session.id,
                                  session.deviceLabel?.isNotEmpty == true ? session.deviceLabel! : l10n.thisDeviceBadge,
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
