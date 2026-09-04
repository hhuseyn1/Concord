import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colors.fgMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.fgMuted, letterSpacing: 0.5),
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
    setState(() => _busy = true);
    try {
      await ref.read(friendsServiceProvider).acceptRequest(request.id);
      if (!mounted) return;
      invalidateFriendsState(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You and ${request.user.username ?? 'this user'} are now friends.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not accept request: ${e.message}')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline(FriendRequestSummary request) async {
    setState(() => _busy = true);
    try {
      await ref.read(friendsServiceProvider).declineRequest(request.id);
      if (!mounted) return;
      invalidateFriendsState(ref);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not decline request: ${e.message}')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(incomingRequestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          icon: Icons.call_received,
          label: 'INCOMING${requestsAsync.maybeWhen(data: (r) => ' - ${r.length}', orElse: () => '')}',
        ),
        const SizedBox(height: ConcordSpacing.xs),
        requestsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: ConcordSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => ConcordEmptyState(
            compact: true,
            title: "Couldn't load incoming requests",
            subtitle: error is ApiException ? error.message : error.toString(),
            action: ConcordButton(
              label: 'Try again',
              variant: ConcordButtonVariant.secondary,
              size: ConcordButtonSize.sm,
              onPressed: () => ref.invalidate(incomingRequestsProvider),
            ),
          ),
          data: (requests) {
            if (requests.isEmpty) {
              return const ConcordEmptyState(compact: true, title: 'No incoming requests.');
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
                          label: 'Accept',
                          size: ConcordButtonSize.sm,
                          onPressed: _busy ? null : () => _accept(request),
                        ),
                        const SizedBox(width: ConcordSpacing.xs),
                        ConcordButton(
                          label: 'Decline',
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
    setState(() => _busy = true);
    try {
      await ref.read(friendsServiceProvider).cancelRequest(request.id);
      if (!mounted) return;
      invalidateFriendsState(ref);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not cancel request: ${e.message}')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(outgoingRequestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          icon: Icons.call_made,
          label: 'OUTGOING${requestsAsync.maybeWhen(data: (r) => ' - ${r.length}', orElse: () => '')}',
        ),
        const SizedBox(height: ConcordSpacing.xs),
        requestsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: ConcordSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => ConcordEmptyState(
            compact: true,
            title: "Couldn't load outgoing requests",
            subtitle: error is ApiException ? error.message : error.toString(),
            action: ConcordButton(
              label: 'Try again',
              variant: ConcordButtonVariant.secondary,
              size: ConcordButtonSize.sm,
              onPressed: () => ref.invalidate(outgoingRequestsProvider),
            ),
          ),
          data: (requests) {
            if (requests.isEmpty) {
              return const ConcordEmptyState(compact: true, title: 'No outgoing requests.');
            }
            return Column(
              children: [
                for (final request in requests)
                  FriendRow(
                    user: request.user,
                    subtitle: 'Pending',
                    actions: ConcordButton(
                      label: 'Cancel',
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
