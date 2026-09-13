import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/billing_providers.dart';
import '../../theme/theme.dart';
import '../../utils/message_time_format.dart';
import '../../widgets/widgets.dart';

const _benefitIcons = [
  Icons.mic,
  Icons.groups_outlined,
  Icons.upload_file_outlined,
  Icons.chat_bubble_outline,
];

List<String> _benefitLabels(AppLocalizations l10n) => [
      l10n.billingBenefitHdVoice,
      l10n.billingBenefitVoiceCapacity,
      l10n.billingBenefitUploadLimit,
      l10n.billingBenefitMessageLength,
];

/// The Billing tab of Settings - see the doc comment on `BillingController`
/// (`lib/providers/billing_providers.dart`) for the full rationale behind the
/// resume-triggered polling this screen wires up below.
class BillingSection extends ConsumerStatefulWidget {
  const BillingSection({super.key});

  @override
  ConsumerState<BillingSection> createState() => _BillingSectionState();
}

class _BillingSectionState extends ConsumerState<BillingSection> with WidgetsBindingObserver {
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
    // The app gets backgrounded while the external browser shows Stripe Checkout/the Customer
    // Portal (there is no `concord://` deep-link return - see `BillingController`'s doc comment
    // for why). Resuming is the only signal we get that the user might be done, so it's what
    // triggers the bounded `GET Billing/Subscription` poll.
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(billingControllerProvider.notifier).refreshAfterResume());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final billingState = ref.watch(billingControllerProvider);

    if (billingState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (billingState.loadError != null) {
      return Center(
        child: ConcordEmptyState(
          icon: Icons.error_outline,
          title: l10n.billingLoadErrorTitle,
          subtitle: billingState.loadError,
          action: ConcordButton(
            label: l10n.tryAgainButton,
            variant: ConcordButtonVariant.secondary,
            size: ConcordButtonSize.sm,
            onPressed: () => ref.read(billingControllerProvider.notifier).load(),
          ),
        ),
      );
    }

    final subscription = billingState.subscription;
    final status = subscription?.status ?? SubscriptionStatus.none;

    Widget card;
    switch (status) {
      case SubscriptionStatus.active:
        card = _ActiveCard(subscription: subscription!, billingState: billingState);
      case SubscriptionStatus.pastDue:
        card = _PastDueCard(billingState: billingState);
      case SubscriptionStatus.none:
      case SubscriptionStatus.canceled:
        card = _SubscribeCard(canceled: status == SubscriptionStatus.canceled, billingState: billingState);
    }

    return ListView(
      padding: const EdgeInsets.all(ConcordSpacing.lg),
      children: [card],
    );
  }
}

/// Maps an `ApiException` to display copy the same way `reset_password_screen.dart` does for its
/// form errors, so Billing's action errors read consistently with the rest of the app.
String _actionErrorMessage(AppLocalizations l10n, ApiException e) {
  if (e.isConnectivityError) return l10n.errorCouldNotReachServer;
  if (e.message.isNotEmpty) return e.message;
  if (e.isServerError) return l10n.errorServerTrouble;
  return l10n.errorSomethingWentWrong;
}

class _ActionError extends StatelessWidget {
  const _ActionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: ConcordSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.sm),
      decoration: BoxDecoration(
        color: colors.dangerBg,
        borderRadius: BorderRadius.circular(ConcordRadii.md),
        border: Border.all(color: colors.danger.withValues(alpha: 0.4)),
      ),
      child: Text(message, style: TextStyle(color: colors.danger, fontSize: 13)),
    );
  }
}

class _BenefitsList extends StatelessWidget {
  const _BenefitsList({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final labels = _benefitLabels(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: ConcordSpacing.sm),
            child: Row(
              children: [
                Icon(_benefitIcons[i], size: compact ? 14 : 16, color: colors.brand),
                const SizedBox(width: ConcordSpacing.sm),
                Expanded(
                  child: Text(
                    labels[i],
                    style: (compact ? textTheme.bodySmall : textTheme.bodyMedium)
                        ?.copyWith(color: compact ? colors.fgMuted : colors.fgDefault),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SubscribeCard extends ConsumerWidget {
  const _SubscribeCard({required this.canceled, required this.billingState});

  final bool canceled;
  final BillingState billingState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(ConcordSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colors.borderSubtle),
        borderRadius: BorderRadius.circular(ConcordRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.billingPremiumTitle, style: textTheme.titleMedium),
          const SizedBox(height: ConcordSpacing.xs),
          Text(l10n.billingPremiumDescription, style: textTheme.bodyMedium?.copyWith(color: colors.fgMuted)),
          if (canceled) ...[
            const SizedBox(height: ConcordSpacing.sm),
            Text(l10n.billingCanceledNotice, style: textTheme.bodySmall?.copyWith(color: colors.fgMuted)),
          ],
          const SizedBox(height: ConcordSpacing.lg),
          Text(
            l10n.billingBenefitsTitle,
            style: textTheme.bodySmall?.copyWith(color: colors.fgMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: ConcordSpacing.sm),
          const _BenefitsList(),
          const SizedBox(height: ConcordSpacing.md),
          if (billingState.launchFailed) _ActionError(message: l10n.billingLaunchFailedError),
          if (billingState.actionException != null)
            _ActionError(message: _actionErrorMessage(l10n, billingState.actionException!)),
          ConcordButton(
            label: l10n.billingSubscribeButton,
            expand: true,
            loading: billingState.actionInFlight,
            onPressed: billingState.actionInFlight
                ? null
                : () => ref.read(billingControllerProvider.notifier).subscribe(),
          ),
        ],
      ),
    );
  }
}

class _ManageSubscriptionButton extends ConsumerWidget {
  const _ManageSubscriptionButton({required this.billingState});

  final BillingState billingState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (billingState.launchFailed) _ActionError(message: l10n.billingLaunchFailedError),
        if (billingState.actionException != null)
          _ActionError(message: _actionErrorMessage(l10n, billingState.actionException!)),
        ConcordButton(
          label: l10n.billingManageSubscriptionButton,
          variant: ConcordButtonVariant.secondary,
          expand: true,
          loading: billingState.actionInFlight,
          onPressed:
              billingState.actionInFlight ? null : () => ref.read(billingControllerProvider.notifier).manage(),
        ),
      ],
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.subscription, required this.billingState});

  final SubscriptionResponse subscription;
  final BillingState billingState;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final endingSoon = subscription.cancelAtPeriodEnd;
    final periodEnd = subscription.currentPeriodEnd;

    return Container(
      padding: const EdgeInsets.all(ConcordSpacing.md),
      decoration: BoxDecoration(
        color: endingSoon ? colors.warningBg : colors.successBg,
        border: Border.all(color: (endingSoon ? colors.warning : colors.success).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(ConcordRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.billingActiveTitle, style: textTheme.titleMedium),
              ConcordBadge(
                label: endingSoon ? l10n.billingEndingBadge : l10n.billingActiveBadge,
                variant: endingSoon ? ConcordBadgeVariant.warning : ConcordBadgeVariant.success,
              ),
            ],
          ),
          if (periodEnd != null) ...[
            const SizedBox(height: ConcordSpacing.sm),
            Text(
              endingSoon
                  ? l10n.billingEndsOn(formatAbsoluteTimestamp(periodEnd))
                  : l10n.billingRenewsOn(formatAbsoluteTimestamp(periodEnd)),
              style: textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: ConcordSpacing.lg),
          Text(
            l10n.billingPerksReminderTitle,
            style: textTheme.bodySmall?.copyWith(color: colors.fgMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: ConcordSpacing.sm),
          const _BenefitsList(compact: true),
          const SizedBox(height: ConcordSpacing.md),
          _ManageSubscriptionButton(billingState: billingState),
        ],
      ),
    );
  }
}

class _PastDueCard extends StatelessWidget {
  const _PastDueCard({required this.billingState});

  final BillingState billingState;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(ConcordSpacing.md),
      decoration: BoxDecoration(
        color: colors.dangerBg,
        border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(ConcordRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.billingPastDueTitle, style: textTheme.titleMedium),
              ConcordBadge(label: l10n.billingPastDueBadge, variant: ConcordBadgeVariant.danger),
            ],
          ),
          const SizedBox(height: ConcordSpacing.sm),
          Text(l10n.billingPastDueDescription, style: textTheme.bodyMedium?.copyWith(color: colors.fgDefault)),
          const SizedBox(height: ConcordSpacing.md),
          _ManageSubscriptionButton(billingState: billingState),
        ],
      ),
    );
  }
}
