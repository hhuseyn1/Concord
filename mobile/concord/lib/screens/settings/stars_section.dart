import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/stars_providers.dart';
import '../../theme/theme.dart';
import '../../utils/api_error_message.dart';
import '../../utils/idempotency_key.dart';
import '../../utils/message_time_format.dart';
import '../../utils/stars_format.dart';
import '../../widgets/widgets.dart';
import 'send_stars_sheet.dart';

class StarsSection extends ConsumerStatefulWidget {
  const StarsSection({super.key});

  @override
  ConsumerState<StarsSection> createState() => _StarsSectionState();
}

class _StarsSectionState extends ConsumerState<StarsSection> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref.read(starsControllerProvider.notifier).refreshAfterResume().then((_) {
          if (mounted) ref.invalidate(starsTransactionsControllerProvider);
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(starsControllerProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.loadError != null || state.wallet == null || state.config == null) {
      return Center(
        child: ConcordEmptyState(
          icon: Icons.star_outline,
          title: l10n.starsLoadErrorTitle,
          subtitle: state.loadError == null ? l10n.starsLoadErrorDescription : apiErrorMessage(l10n, state.loadError!),
          action: ConcordButton(
            label: l10n.tryAgainButton,
            variant: ConcordButtonVariant.secondary,
            size: ConcordButtonSize.sm,
            onPressed: () => ref.read(starsControllerProvider.notifier).load(),
          ),
        ),
      );
    }

    final config = state.config!;

    return ListView(
      padding: const EdgeInsets.all(ConcordSpacing.lg),
      children: [
        _BalanceCard(state: state),
        const SizedBox(height: ConcordSpacing.xl),
        const _PremiumTrialCard(),
        const SizedBox(height: ConcordSpacing.xl),
        _PackagesList(packages: config.packages),
        const SizedBox(height: ConcordSpacing.xl),
        const _TransactionHistory(),
      ],
    );
  }
}

class _StarsCard extends StatelessWidget {
  const _StarsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ConcordSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceSidebar,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(ConcordRadii.md),
      ),
      child: child,
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.state});

  final StarsState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final config = state.config!;

    return _StarsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.starsBalanceLabel.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(color: colors.fgMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: ConcordSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.star, size: 24, color: colors.warning),
              const SizedBox(width: ConcordSpacing.sm),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: ConcordSpacing.sm,
                  children: [
                    Text(formatStars(state.balance, localeName), style: textTheme.headlineSmall),
                    Text(l10n.starsUnit, style: textTheme.bodyMedium?.copyWith(color: colors.fgMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ConcordSpacing.sm),
          Text(
            l10n.starsEarnHint(
              config.chatRewardAmount,
              config.chatRewardDailyCap,
              config.chatRewardCooldownSeconds,
            ),
            style: textTheme.bodySmall?.copyWith(color: colors.fgMuted),
          ),
          const SizedBox(height: ConcordSpacing.md),
          ConcordButton(
            label: l10n.starsSendButton,
            leading: const Icon(Icons.send_outlined, size: 16),
            expand: true,
            onPressed: state.balance <= 0 ? null : () => showSendStarsSheet(context),
          ),
        ],
      ),
    );
  }
}

class _PremiumTrialCard extends ConsumerStatefulWidget {
  const _PremiumTrialCard();

  @override
  ConsumerState<_PremiumTrialCard> createState() => _PremiumTrialCardState();
}

class _PremiumTrialCardState extends ConsumerState<_PremiumTrialCard> {
  String _idempotencyKey = newIdempotencyKey();
  String? _error;

  Future<void> _activate(StarsState state) async {
    final l10n = AppLocalizations.of(context);
    final config = state.config!;
    final balanceAfter = (state.balance - config.premiumTrialCostStars).clamp(0, state.balance);

    final confirmed = await showConfirmDialog(
      context,
      title: l10n.starsTrialConfirmTitle,
      message: l10n.starsTrialConfirmDescription(
        config.premiumTrialCostStars,
        config.premiumTrialDurationDays,
        balanceAfter,
      ),
      confirmLabel: l10n.starsTrialConfirmAction(config.premiumTrialCostStars),
      isDestructive: false,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _error = null);
    final failure = await ref.read(starsControllerProvider.notifier).activatePremiumTrial(_idempotencyKey);
    if (!mounted) return;

    if (failure != null) {
      setState(() => _error = mapPremiumTrialError(l10n, failure));
      return;
    }

    _idempotencyKey = newIdempotencyKey();
    ref.invalidate(starsTransactionsControllerProvider);
    final expiresAt = ref.read(starsControllerProvider).wallet?.premiumTrialExpiresAt;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.starsTrialSuccessSnackbar(expiresAt == null ? '' : formatAbsoluteTimestamp(expiresAt)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(starsControllerProvider);
    final config = state.config!;
    final wallet = state.wallet!;
    final missing = (config.premiumTrialCostStars - state.balance).clamp(0, config.premiumTrialCostStars);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.starsTrialSectionTitle, style: textTheme.titleMedium),
        const SizedBox(height: ConcordSpacing.sm),
        _StarsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: ConcordSpacing.sm,
                runSpacing: ConcordSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: colors.brand),
                      const SizedBox(width: ConcordSpacing.xs),
                      Flexible(child: Text(l10n.starsTrialTitle, style: textTheme.bodyLarge)),
                    ],
                  ),
                  if (wallet.premiumTrialActive)
                    ConcordBadge(
                      label: l10n.starsTrialActiveBadge,
                      variant: ConcordBadgeVariant.success,
                    ),
                ],
              ),
              const SizedBox(height: ConcordSpacing.sm),
              Text(
                l10n.starsTrialDescription(config.premiumTrialCostStars, config.premiumTrialDurationDays),
                style: textTheme.bodyMedium?.copyWith(color: colors.fgMuted),
              ),
              if (wallet.premiumTrialActive && wallet.premiumTrialExpiresAt != null) ...[
                const SizedBox(height: ConcordSpacing.sm),
                Text(
                  l10n.starsTrialExpiresOn(formatAbsoluteTimestamp(wallet.premiumTrialExpiresAt!)),
                  style: textTheme.bodyMedium,
                ),
              ] else if (wallet.hasActivePremium) ...[
                const SizedBox(height: ConcordSpacing.sm),
                Text(l10n.starsTrialAlreadyPremium, style: textTheme.bodyMedium),
              ] else if (missing > 0) ...[
                const SizedBox(height: ConcordSpacing.sm),
                Text(
                  l10n.starsTrialInsufficient(missing),
                  style: textTheme.bodyMedium?.copyWith(color: colors.warning),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: ConcordSpacing.sm),
                _InlineMessage(message: _error!, tone: _MessageTone.danger),
              ],
              if (!wallet.premiumTrialActive && !wallet.hasActivePremium) ...[
                const SizedBox(height: ConcordSpacing.md),
                ConcordButton(
                  label: l10n.starsTrialAction,
                  expand: true,
                  loading: state.trialInFlight,
                  onPressed: missing > 0 || state.trialInFlight ? null : () => _activate(state),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PackagesList extends ConsumerStatefulWidget {
  const _PackagesList({required this.packages});

  final List<StarPackage> packages;

  @override
  ConsumerState<_PackagesList> createState() => _PackagesListState();
}

class _PackagesListState extends ConsumerState<_PackagesList> {
  String? _error;

  Future<void> _buy(StarPackage package) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);
    final failure = await ref.read(starsControllerProvider.notifier).buyPackage(package.id);
    if (!mounted || failure == null) return;
    setState(() => _error = mapStarsCheckoutError(l10n, failure));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final state = ref.watch(starsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.starsPackagesTitle, style: textTheme.titleMedium),
        const SizedBox(height: ConcordSpacing.xs),
        Text(l10n.starsPackagesDescription, style: textTheme.bodySmall?.copyWith(color: colors.fgMuted)),
        const SizedBox(height: ConcordSpacing.sm),
        if (state.launchFailed) ...[
          _InlineMessage(message: l10n.starsPurchaseLaunchFailedError, tone: _MessageTone.danger),
          const SizedBox(height: ConcordSpacing.sm),
        ],
        if (_error != null) ...[
          _InlineMessage(message: _error!, tone: _MessageTone.danger),
          const SizedBox(height: ConcordSpacing.sm),
        ],
        if (state.pendingStripeFlow) ...[
          _InlineMessage(message: l10n.starsPurchasePendingNotice, tone: _MessageTone.info),
          const SizedBox(height: ConcordSpacing.sm),
        ],
        if (widget.packages.isEmpty)
          ConcordEmptyState(compact: true, icon: Icons.shopping_bag_outlined, title: l10n.starsPackagesEmpty)
        else
          for (final package in widget.packages)
            Padding(
              padding: const EdgeInsets.only(bottom: ConcordSpacing.sm),
              child: _StarsCard(
                child: Row(
                  children: [
                    Icon(Icons.star, size: 20, color: colors.warning),
                    const SizedBox(width: ConcordSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.starsPackageAmount(package.stars), style: textTheme.bodyLarge),
                          Text(
                            formatPackagePrice(package.priceAmount, package.currency, localeName),
                            style: textTheme.bodySmall?.copyWith(color: colors.fgMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: ConcordSpacing.sm),
                    ConcordButton(
                      label: l10n.starsPackageBuyButton,
                      size: ConcordButtonSize.sm,
                      loading: state.purchasingPackageId == package.id,
                      onPressed: state.purchasingPackageId != null ? null : () => _buy(package),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _TransactionHistory extends ConsumerWidget {
  const _TransactionHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(starsTransactionsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.starsHistoryTitle, style: textTheme.titleMedium),
        const SizedBox(height: ConcordSpacing.sm),
        if (state.isLoading)
          const Padding(
            padding: EdgeInsets.all(ConcordSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.loadError != null)
          ConcordEmptyState(
            compact: true,
            icon: Icons.error_outline,
            title: l10n.starsHistoryErrorTitle,
            subtitle: apiErrorMessage(l10n, state.loadError!),
            action: ConcordButton(
              label: l10n.tryAgainButton,
              variant: ConcordButtonVariant.secondary,
              size: ConcordButtonSize.sm,
              onPressed: () => ref.read(starsTransactionsControllerProvider.notifier).retryInitialLoad(),
            ),
          )
        else if (state.items.isEmpty)
          ConcordEmptyState(
            compact: true,
            icon: Icons.history,
            title: l10n.starsHistoryEmpty,
            subtitle: l10n.starsHistoryEmptyDescription,
          )
        else ...[
          for (final transaction in state.items) _TransactionRow(transaction: transaction),
          if (state.hasMore)
            Padding(
              padding: const EdgeInsets.only(top: ConcordSpacing.sm),
              child: ConcordButton(
                label: l10n.loadMoreButton,
                variant: ConcordButtonVariant.secondary,
                size: ConcordButtonSize.sm,
                expand: true,
                loading: state.isLoadingMore,
                onPressed: () => ref.read(starsTransactionsControllerProvider.notifier).loadMore(),
              ),
            ),
        ],
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final StarTransactionResponse transaction;

  IconData get _icon => switch (transaction.type) {
    StarTransactionType.chatReward => Icons.chat_bubble_outline,
    StarTransactionType.transferReceived => Icons.call_received,
    StarTransactionType.transferSent => Icons.call_made,
    StarTransactionType.premiumTrialPurchase => Icons.auto_awesome,
    StarTransactionType.packagePurchase => Icons.shopping_bag_outlined,
    StarTransactionType.unknown => Icons.star_outline,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final signed = transaction.signedAmount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 18, color: colors.fgMuted),
          const SizedBox(width: ConcordSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(starsTransactionLabel(l10n, transaction), style: textTheme.bodyMedium),
                Text(
                  formatAbsoluteTimestamp(transaction.created),
                  style: textTheme.labelSmall?.copyWith(color: colors.fgFaint),
                ),
              ],
            ),
          ),
          const SizedBox(width: ConcordSpacing.sm),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatSignedStars(signed, localeName),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: signed < 0 ? colors.fgDefault : colors.success,
                  ),
                ),
                Text(
                  l10n.starsHistoryBalanceAfter(transaction.balanceAfter),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(color: colors.fgFaint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _MessageTone { danger, info }

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.tone});

  final String message;
  final _MessageTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final (background, foreground) = switch (tone) {
      _MessageTone.danger => (colors.dangerBg, colors.danger),
      _MessageTone.info => (colors.infoBg, colors.info),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ConcordRadii.md),
        border: Border.all(color: foreground.withValues(alpha: 0.4)),
      ),
      child: Text(message, style: textTheme.bodyMedium?.copyWith(color: foreground)),
    );
  }
}

class StarsBalanceChip extends ConsumerWidget {
  const StarsBalanceChip({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final state = ref.watch(starsControllerProvider);
    final wallet = state.wallet;
    if (state.isLoading || wallet == null) return const SizedBox.shrink();

    final label = formatStars(wallet.balance, localeName);

    return Tooltip(
      message: l10n.starsIndicatorTooltip(wallet.balance),
      child: Material(
        color: colors.fgDefault.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ConcordRadii.full),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ConcordRadii.full),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.sm, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 12, color: colors.warning),
                const SizedBox(width: ConcordSpacing.xs),
                Text(label, style: textTheme.labelSmall?.copyWith(color: colors.fgDefault)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
