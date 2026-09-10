import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../providers/friends_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'friend_row.dart';

const _minQueryLength = 2;
const _debounce = Duration(milliseconds: 350);

class AddFriendTab extends ConsumerStatefulWidget {
  const AddFriendTab({super.key});

  @override
  ConsumerState<AddFriendTab> createState() => _AddFriendTabState();
}

class _AddFriendTabState extends ConsumerState<AddFriendTab> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _query = '';
  bool _isSearching = false;
  Object? _searchError;
  List<PublicProfileResponse>? _results;
  final Set<String> _pendingUserIds = {};

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleQueryChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () => _runSearch(value.trim()));
  }

  Future<void> _runSearch(String trimmed) async {
    if (!mounted) return;
    setState(() => _query = trimmed);
    if (trimmed.length < _minQueryLength) {
      setState(() {
        _results = null;
        _searchError = null;
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final results = await ref.read(usersServiceProvider).search(trimmed);
      if (!mounted || _query != trimmed) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted || _query != trimmed) return;
      setState(() {
        _searchError = e;
        _isSearching = false;
      });
    }
  }

  Future<void> _sendRequest(PublicProfileResponse user) async {
    setState(() => _pendingUserIds.add(user.id));
    try {
      await ref.read(friendsServiceProvider).sendRequest(user.id);
      if (!mounted) return;
      invalidateFriendsState(ref);
      await _runSearch(_query);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).errorSendRequestFailed(e.message))));
    } finally {
      if (mounted) setState(() => _pendingUserIds.remove(user.id));
    }
  }

  Future<void> _acceptRequest(PublicProfileResponse user) async {
    final requestId = user.pendingRequestId;
    if (requestId == null) return;
    setState(() => _pendingUserIds.add(user.id));
    try {
      await ref.read(friendsServiceProvider).acceptRequest(requestId);
      if (!mounted) return;
      invalidateFriendsState(ref);
      await _runSearch(_query);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).errorAcceptRequestFailed(e.message))));
    } finally {
      if (mounted) setState(() => _pendingUserIds.remove(user.id));
    }
  }

  Future<void> _declineRequest(PublicProfileResponse user) async {
    final requestId = user.pendingRequestId;
    if (requestId == null) return;
    setState(() => _pendingUserIds.add(user.id));
    try {
      await ref.read(friendsServiceProvider).declineRequest(requestId);
      if (!mounted) return;
      invalidateFriendsState(ref);
      await _runSearch(_query);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).errorDeclineRequestFailed(e.message))));
    } finally {
      if (mounted) setState(() => _pendingUserIds.remove(user.id));
    }
  }

  Widget _actionsFor(AppLocalizations l10n, PublicProfileResponse user) {
    final pending = _pendingUserIds.contains(user.id);

    switch (user.relationshipStatus) {
      case FriendRelationshipStatus.friends:
        return ConcordBadge(label: l10n.alreadyFriendsBadge, variant: ConcordBadgeVariant.neutral);
      case FriendRelationshipStatus.outgoingRequest:
        return ConcordButton(
          label: l10n.requestSentLabel,
          variant: ConcordButtonVariant.secondary,
          size: ConcordButtonSize.sm,
        );
      case FriendRelationshipStatus.incomingRequest:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConcordButton(
              label: l10n.acceptButton,
              size: ConcordButtonSize.sm,
              loading: pending,
              onPressed: pending ? null : () => _acceptRequest(user),
            ),
            const SizedBox(width: ConcordSpacing.xs),
            ConcordButton(
              label: l10n.declineButton,
              variant: ConcordButtonVariant.secondary,
              size: ConcordButtonSize.sm,
              onPressed: pending ? null : () => _declineRequest(user),
            ),
          ],
        );
      case FriendRelationshipStatus.blocked:
      case FriendRelationshipStatus.none:
        return ConcordButton(
          label: l10n.addButton,
          size: ConcordButtonSize.sm,
          loading: pending,
          onPressed: pending ? null : () => _sendRequest(user),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);
    final enabled = _query.length >= _minQueryLength;

    return ListView(
      padding: const EdgeInsets.all(ConcordSpacing.md),
      children: [
        ConcordTextField(
          controller: _searchController,
          hint: l10n.searchByUsernameHint,
          onChanged: _handleQueryChanged,
        ),
        const SizedBox(height: ConcordSpacing.md),
        if (_query.isNotEmpty && !enabled)
          Text(
            l10n.keepTypingMessage(_minQueryLength),
            style: TextStyle(fontSize: 13, color: colors.fgMuted),
          ),
        if (_query.isEmpty)
          ConcordEmptyState(
            icon: Icons.person_add_alt_outlined,
            title: l10n.findFriendsTitle,
            subtitle: l10n.findFriendsSubtitle,
          ),
        if (enabled && _isSearching) const Center(child: Padding(padding: EdgeInsets.all(ConcordSpacing.lg), child: CircularProgressIndicator())),
        if (enabled && !_isSearching && _searchError != null)
          ConcordEmptyState(
            title: l10n.searchFailedTitle,
            subtitle: _searchError is ApiException ? (_searchError! as ApiException).message : _searchError.toString(),
          ),
        if (enabled && !_isSearching && _searchError == null && (_results?.isEmpty ?? false))
          ConcordEmptyState(
            icon: Icons.search_off,
            title: l10n.noUsersFoundTitle,
            subtitle: l10n.noUsersFoundSubtitle(_query),
          ),
        if (enabled && !_isSearching && _searchError == null && (_results?.isNotEmpty ?? false))
          for (final user in _results!) FriendRow(user: user, actions: _actionsFor(l10n, user)),
      ],
    );
  }
}
