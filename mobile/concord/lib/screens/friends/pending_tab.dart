import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../providers/friends_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'friend_row.dart';

class PendingTab extends ConsumerWidget {
  const PendingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.md),
      children: const [
        _IncomingSection(),
        SizedBox(height: ConcordSpacing.lg),
        _OutgoingSection(),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final type = ConcordTypography.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colors.fgMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: type.size(12), fontWeight: FontWeight.w600, color: colors.fgMuted, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

class _IncomingSection extends ConsumerStatefulWidget {
  const _IncomingSection();

  @override
  ConsumerState<_IncomingSection> createState() => _IncomingSectionState();
}

class _IncomingSectionState extends ConsumerState<_IncomingSection> {
  bool _busy = false;

  Future<void> _accept(FriendRequestSummary request) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(friendsServiceProvider).acceptRequest(request.id);
      if (!mounted) return;
      invalidateFriendsState(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.nowFriendsSnackbar(request.user.username ?? l10n.thisUserFallback))),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorAcceptRequestFailed(e.message))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline(FriendRequestSummary request) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(friendsServiceProvider).declineRequest(request.id);
      if (!mounted) return;
      invalidateFriendsState(ref);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorDeclineRequestFailed(e.message))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requestsAsync = ref.watch(incomingRequestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          icon: Icons.call_received,
          label: '${l10n.incomingHeader}${requestsAsync.maybeWhen(data: (r) => l10n.sectionCountSuffix(r.length), orElse: () => '')}',
        ),
        const SizedBox(height: ConcordSpacing.xs),
        requestsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: ConcordSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => ConcordEmptyState(
            compact: true,
            title: l10n.couldNotLoadIncomingTitle,
            subtitle: error is ApiException ? error.message : error.toString(),
            action: ConcordButton(
              label: l10n.tryAgainButton,
              variant: ConcordButtonVariant.secondary,
              size: ConcordButtonSize.sm,
              onPressed: () => ref.invalidate(incomingRequestsProvider),
            ),
          ),
          data: (requests) {
            if (requests.isEmpty) {
              return ConcordEmptyState(compact: true, title: l10n.noIncomingRequestsText);
            }
            return Column(
              children: [
                for (final request in requests)
                  FriendRow(
                    user: request.user,
                    actions: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConcordButton(
                          label: l10n.acceptButton,
                          size: ConcordButtonSize.sm,
                          onPressed: _busy ? null : () => _accept(request),
                        ),
                        const SizedBox(width: ConcordSpacing.xs),
                        ConcordButton(
                          label: l10n.declineButton,
                          variant: ConcordButtonVariant.secondary,
                          size: ConcordButtonSize.sm,
                          onPressed: _busy ? null : () => _decline(request),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _OutgoingSection extends ConsumerStatefulWidget {
  const _OutgoingSection();

  @override
  ConsumerState<_OutgoingSection> createState() => _OutgoingSectionState();
}

class _OutgoingSectionState extends ConsumerState<_OutgoingSection> {
  bool _busy = false;

  Future<void> _cancel(FriendRequestSummary request) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.cancelRequestConfirmTitle,
      message: l10n.cancelRequestConfirmMessage(request.user.username ?? l10n.thisUserFallback),
      confirmLabel: l10n.cancelRequestButton,
    );
    if (confirmed != true) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(friendsServiceProvider).cancelRequest(request.id);
      if (!mounted) return;
      invalidateFriendsState(ref);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorCancelRequestFailed(e.message))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requestsAsync = ref.watch(outgoingRequestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          icon: Icons.call_made,
          label: '${l10n.outgoingHeader}${requestsAsync.maybeWhen(data: (r) => l10n.sectionCountSuffix(r.length), orElse: () => '')}',
        ),
        const SizedBox(height: ConcordSpacing.xs),
        requestsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: ConcordSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => ConcordEmptyState(
            compact: true,
            title: l10n.couldNotLoadOutgoingTitle,
            subtitle: error is ApiException ? error.message : error.toString(),
            action: ConcordButton(
              label: l10n.tryAgainButton,
              variant: ConcordButtonVariant.secondary,
              size: ConcordButtonSize.sm,
              onPressed: () => ref.invalidate(outgoingRequestsProvider),
            ),
          ),
          data: (requests) {
            if (requests.isEmpty) {
              return ConcordEmptyState(compact: true, title: l10n.noOutgoingRequestsText);
            }
            return Column(
              children: [
                for (final request in requests)
                  FriendRow(
                    user: request.user,
                    subtitle: l10n.pendingSubtitle,
                    actions: ConcordButton(
                      label: l10n.cancelButton,
                      variant: ConcordButtonVariant.secondary,
                      size: ConcordButtonSize.sm,
                      onPressed: _busy ? null : () => _cancel(request),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
