import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_controller.dart';
import '../../providers/friends_providers.dart';
import '../../providers/paged_list_controller.dart';
import '../../providers/stars_providers.dart';
import '../../theme/theme.dart';
import '../../utils/api_error_message.dart';
import '../../utils/idempotency_key.dart';
import '../../utils/stars_format.dart';
import '../../widgets/widgets.dart';

/// Above either of these, sending asks for an explicit confirmation - an
/// absolute amount that's meaningful on its own, or a big slice of what the
/// user holds. Same thresholds as the web app's `SendStarsModal`.
const _confirmAbsoluteThreshold = 100;
const _confirmBalanceFraction = 0.5;

/// Opens the "Send Stars" flow. Returns once the sheet is closed.
///
/// `isScrollControlled` + a height cap + the keyboard inset padding inside:
/// the sheet holds a search field, a friend list and an amount field, so on a
/// 320x568 screen with the keyboard up and Extra large text it has to scroll
/// rather than clip.
Future<void> showSendStarsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => const _SendStarsSheet(),
  );
}

class _SendStarsSheet extends ConsumerStatefulWidget {
  const _SendStarsSheet();

  @override
  ConsumerState<_SendStarsSheet> createState() => _SendStarsSheetState();
}

class _SendStarsSheetState extends ConsumerState<_SendStarsSheet> {
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();

  /// One key per attempt: held across retries of the same send (so a request
  /// the user retries after a timeout can't double-spend) and only replaced
  /// once the send finally succeeds. Reopening the sheet remounts this state,
  /// which starts a brand-new attempt with a brand-new key.
  String _idempotencyKey = newIdempotencyKey();

  PublicProfileResponse? _recipient;
  String _query = '';
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _friendName(PublicProfileResponse user, AppLocalizations l10n) {
    if (user.username?.isNotEmpty == true) return user.username!;
    final full = [user.name, user.surname].where((part) => part != null && part.isNotEmpty).join(' ');
    return full.isNotEmpty ? full : l10n.starsUnknownUser;
  }

  int? get _parsedAmount => int.tryParse(_amountController.text.trim());

  String? _validate(AppLocalizations l10n, int balance) {
    final currentUserId = ref.read(authControllerProvider).profile?.id;
    if (_recipient == null) return l10n.starsSendErrorNoRecipient;
    if (_recipient!.id == currentUserId) return l10n.starsSendErrorSelf;
    if (_amountController.text.trim().isEmpty) return l10n.starsSendErrorAmountRequired;
    final amount = _parsedAmount;
    if (amount == null || amount <= 0) return l10n.starsSendErrorAmountPositive;
    if (amount > balance) return l10n.starsSendErrorAmountTooLarge(balance);
    return null;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final balance = ref.read(starsControllerProvider).balance;
    final error = _validate(l10n, balance);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    final amount = _parsedAmount!;
    final recipient = _recipient!;
    final name = _friendName(recipient, l10n);

    final needsConfirmation =
        amount >= _confirmAbsoluteThreshold || (balance > 0 && amount >= balance * _confirmBalanceFraction);
    if (needsConfirmation) {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.starsSendConfirmTitle,
        message: l10n.starsSendConfirmDescription(amount, name, balance - amount),
        confirmLabel: l10n.starsSendConfirmAction(amount),
        // Spending Stars is irreversible but not destructive in the
        // delete-my-data sense, so this keeps the neutral (non-red) styling.
        isDestructive: false,
      );
      if (confirmed != true) return;
    }

    setState(() => _error = null);
    final failure = await ref.read(starsControllerProvider.notifier).transfer(
          recipientUserId: recipient.id,
          amount: amount,
          idempotencyKey: _idempotencyKey,
        );
    if (!mounted) return;

    if (failure != null) {
      // The key deliberately stays put: an immediate retry is the *same*
      // attempt as far as the server is concerned.
      setState(() => _error = mapTransferError(l10n, failure));
      return;
    }

    // Attempt finished for good - the next send starts a new one.
    _idempotencyKey = newIdempotencyKey();
    ref.invalidate(starsTransactionsControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.starsSendSuccessSnackbar(amount, name))));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final starsState = ref.watch(starsControllerProvider);
    final friendsState = ref.watch(friendsListControllerProvider);
    final currentUserId = ref.watch(authControllerProvider).profile?.id;
    final balance = starsState.balance;

    final friends = friendsState.items
        .where((user) => user.id != currentUserId)
        .where((user) =>
            _query.isEmpty || _friendName(user, l10n).toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Padding(
      // Lifts the sheet above the software keyboard instead of letting it sit
      // under the amount field.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(ConcordSpacing.lg),
          children: [
            Text(l10n.starsSendTitle, style: textTheme.titleMedium),
            const SizedBox(height: ConcordSpacing.xs),
            Text(l10n.starsSendDescription, style: textTheme.bodySmall?.copyWith(color: colors.fgMuted)),
            const SizedBox(height: ConcordSpacing.lg),
            Text(l10n.starsSendRecipientLabel, style: textTheme.labelLarge),
            const SizedBox(height: ConcordSpacing.sm),
            _RecipientPicker(
              friends: friends,
              state: friendsState,
              query: _query,
              selectedId: _recipient?.id,
              nameOf: (user) => _friendName(user, l10n),
              onSearchChanged: (value) => setState(() => _query = value.trim()),
              searchController: _searchController,
              onSelect: (user) => setState(() {
                _recipient = user;
                _error = null;
              }),
            ),
            const SizedBox(height: ConcordSpacing.lg),
            ConcordTextField(
              controller: _amountController,
              label: l10n.starsSendAmountLabel,
              hint: '0',
              keyboardType: TextInputType.number,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: ConcordSpacing.xs),
            Text(
              balance > 0 ? l10n.starsSendAmountHint(balance) : l10n.starsSendNoBalance,
              style: textTheme.bodySmall?.copyWith(color: colors.fgMuted),
            ),
            if (_error != null) ...[
              const SizedBox(height: ConcordSpacing.sm),
              _InlineError(message: _error!),
            ],
            const SizedBox(height: ConcordSpacing.lg),
            // Wrap, not Row: at Extra large text "Cancel" + "Send" stop fitting
            // side by side on a 320pt sheet, and wrapping to two rows beats
            // ellipsizing a button label.
            Wrap(
              alignment: WrapAlignment.end,
              spacing: ConcordSpacing.sm,
              runSpacing: ConcordSpacing.sm,
              children: [
                ConcordButton(
                  label: l10n.cancelButton,
                  variant: ConcordButtonVariant.secondary,
                  onPressed: starsState.transferInFlight ? null : () => Navigator.of(context).pop(),
                ),
                ConcordButton(
                  label: l10n.starsSendSubmitButton,
                  loading: starsState.transferInFlight,
                  onPressed: starsState.transferInFlight || balance <= 0 ? null : _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientPicker extends ConsumerWidget {
  const _RecipientPicker({
    required this.friends,
    required this.state,
    required this.query,
    required this.selectedId,
    required this.nameOf,
    required this.onSelect,
    required this.onSearchChanged,
    required this.searchController,
  });

  final List<PublicProfileResponse> friends;
  final PagedListState<PublicProfileResponse> state;
  final String query;
  final String? selectedId;
  final String Function(PublicProfileResponse user) nameOf;
  final ValueChanged<PublicProfileResponse> onSelect;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(ConcordRadii.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(ConcordSpacing.sm),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: l10n.starsSendSearchHint,
                prefixIcon: Icon(Icons.search, size: 18, color: colors.fgMuted),
                isDense: true,
              ),
            ),
          ),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(ConcordSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.loadError != null)
            ConcordEmptyState(
              compact: true,
              icon: Icons.error_outline,
              title: l10n.starsSendFriendsErrorTitle,
              subtitle: apiErrorMessage(l10n, state.loadError!),
              action: ConcordButton(
                label: l10n.tryAgainButton,
                variant: ConcordButtonVariant.secondary,
                size: ConcordButtonSize.sm,
                onPressed: () => ref.read(friendsListControllerProvider.notifier).retryInitialLoad(),
              ),
            )
          else if (friends.isEmpty)
            ConcordEmptyState(
              compact: true,
              icon: Icons.group_outlined,
              title: query.isEmpty ? l10n.starsSendNoFriends : l10n.starsSendNoMatches(query),
              subtitle: query.isEmpty ? l10n.starsSendNoFriendsDescription : null,
            )
          else
            // Height-capped and independently scrollable so a long friends list
            // can't push the amount field and the actions off the sheet.
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final user = friends[index];
                  final selected = user.id == selectedId;
                  return ListTile(
                    dense: true,
                    selected: selected,
                    selectedTileColor: colors.brandBg,
                    leading: ConcordAvatar(
                      imageUrl: user.avatarUrl,
                      name: nameOf(user),
                      size: ConcordAvatarSize.sm,
                    ),
                    title: Text(nameOf(user), overflow: TextOverflow.ellipsis),
                    trailing: selected ? Icon(Icons.check, color: colors.brand) : null,
                    onTap: () => onSelect(user),
                  );
                },
              ),
            ),
          if (state.hasMore && query.isEmpty)
            Padding(
              padding: const EdgeInsets.all(ConcordSpacing.sm),
              child: ConcordButton(
                label: l10n.loadMoreButton,
                variant: ConcordButtonVariant.ghost,
                size: ConcordButtonSize.sm,
                expand: true,
                loading: state.isLoadingMore,
                onPressed: () => ref.read(friendsListControllerProvider.notifier).loadMore(),
              ),
            ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.sm),
      decoration: BoxDecoration(
        color: colors.dangerBg,
        borderRadius: BorderRadius.circular(ConcordRadii.md),
        border: Border.all(color: colors.danger.withValues(alpha: 0.4)),
      ),
      child: Text(message, style: textTheme.bodyMedium?.copyWith(color: colors.danger)),
    );
  }
}
