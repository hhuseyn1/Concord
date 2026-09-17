import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api.dart';
import 'api_providers.dart';

class BillingState {
  const BillingState({
    this.subscription,
    this.isLoading = true,
    this.loadError,
    this.actionInFlight = false,
    this.actionException,
    this.launchFailed = false,
    this.pendingStripeFlow = false,
  });

  final SubscriptionResponse? subscription;
  final bool isLoading;
  final ApiException? loadError;

  /// True while a Subscribe/Manage-subscription request (or the subsequent external-browser
  /// launch) is in flight - separate from [isLoading], which only covers the initial/retry load,
  /// so the Subscribe and Manage buttons can show their own spinner without touching the
  /// full-section loading state (mirrors `revokingId`'s role in `SessionsListState`).
  final bool actionInFlight;

  /// Set when `createCheckoutSession`/`createPortalSession` itself failed. The billing screen
  /// maps this to copy the same way `reset_password_screen.dart` maps its `ApiException`s.
  final ApiException? actionException;

  /// Set when the API call succeeded but `url_launcher` reported it couldn't open the returned
  /// URL at all (distinct from [actionException] - the request never failed, the launch did).
  final bool launchFailed;

  /// True once a Checkout/Portal URL has been launched in the external browser and we're
  /// waiting to find out (via [BillingController.refreshAfterResume]) whether the user actually
  /// completed anything. See the doc comment on [BillingController] for why this exists.
  final bool pendingStripeFlow;

  BillingState copyWith({
    SubscriptionResponse? subscription,
    bool? isLoading,
    ApiException? loadError,
    bool clearLoadError = false,
    bool? actionInFlight,
    ApiException? actionException,
    bool clearActionException = false,
    bool? launchFailed,
    bool? pendingStripeFlow,
  }) {
    return BillingState(
      subscription: subscription ?? this.subscription,
      isLoading: isLoading ?? this.isLoading,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      actionInFlight: actionInFlight ?? this.actionInFlight,
      actionException: clearActionException ? null : (actionException ?? this.actionException),
      launchFailed: launchFailed ?? (clearActionException ? false : this.launchFailed),
      pendingStripeFlow: pendingStripeFlow ?? this.pendingStripeFlow,
    );
  }
}

/// Drives the Billing tab: loads `GET Billing/Subscription`, and starts the Subscribe/Manage
/// Stripe flows.
///
/// ## Why this polls on resume instead of using a deep-link return
///
/// `Billing/CheckoutSession` and `Billing/PortalSession` bake a fixed, backend-configured
/// `success_url`/`cancel_url`/`return_url` into the session they create, and it always points at
/// the *web* app (`.../cabinet/checkout/...`, `.../cabinet/settings?tab=billing`) - there's no
/// per-request override, so Stripe has no way to redirect back into this app via the `concord://`
/// scheme once the user finishes in the external browser. Changing that is a backend change and
/// out of scope here.
///
/// Instead: the Subscribe/Manage buttons open the Stripe URL with
/// `launchUrl(..., mode: LaunchMode.externalApplication)`, which backgrounds this app. When the
/// OS brings Concord back to the foreground, the billing screen's `WidgetsBindingObserver` calls
/// [refreshAfterResume], which re-polls `GET Billing/Subscription` a few times (bounded, a couple
/// of seconds apart) so a webhook that's still in flight has a chance to land before we give up.
/// There's no reliable signal for "the browser really was showing our Checkout/Portal page" vs.
/// "the user switched to some other app and back", so a poll that finds nothing changed is a
/// normal, silent outcome - not an error.
///
/// Future-proofing: this app already has a working `concord://` scheme with router-level
/// deep-link normalization (see `lib/router/app_router.dart`, used today for password-reset and
/// invite links). If the backend is ever extended to accept a per-request return URL, a
/// `concord://billing/checkout-return` route could replace this resume-polling approach for a
/// snappier, unambiguous UX. Not built now - just the natural next step.
class BillingController extends StateNotifier<BillingState> {
  BillingController(this._ref) : super(const BillingState()) {
    unawaited(load());
  }

  final Ref _ref;
  bool _disposed = false;

  /// Snapshot of the subscription status taken right when a Stripe flow was launched, so
  /// [refreshAfterResume] can stop polling early once something actually changed instead of
  /// always running the full bounded window.
  SubscriptionStatus? _statusAtFlowStart;
  bool? _cancelAtPeriodEndAtFlowStart;

  static const _pollInterval = Duration(seconds: 2);
  // ~16s bounded window: long enough for a webhook that's already in flight to land, short
  // enough to not leave the user staring at nothing happening if they just looked around and
  // came back without completing anything.
  static const _pollMaxAttempts = 8;

  BillingService get _service => _ref.read(billingServiceProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearLoadError: true);
    try {
      final subscription = await _service.getSubscription();
      if (_disposed) return;
      state = state.copyWith(subscription: subscription, isLoading: false);
    } on ApiException catch (e) {
      if (_disposed) return;
      state = state.copyWith(isLoading: false, loadError: e);
    }
  }

  /// Subscribe-button handler. Full iOS/Android distribution-compliance note: current (2026)
  /// App Store policy allows linking out to a Stripe-hosted purchase flow for digital content as
  /// long as it opens the full external browser rather than an in-app WebView, which is exactly
  /// what [_launchStripeFlow] does below. Whether Apple's in-app purchase must *also* be offered
  /// as a parallel option is a separate, evolving business/legal decision outside this task's
  /// scope - not implemented here, and intentionally left as just this comment rather than a
  /// blocking follow-up item.
  Future<void> subscribe() => _launchStripeFlow(() async => (await _service.createCheckoutSession()).url);

  /// Manage-subscription-button handler (same external-browser-only approach as [subscribe]).
  Future<void> manage() => _launchStripeFlow(() async => (await _service.createPortalSession()).url);

  Future<void> _launchStripeFlow(Future<String> Function() createUrl) async {
    if (state.actionInFlight) return; // guard against duplicate taps / re-entrant calls
    state = state.copyWith(actionInFlight: true, clearActionException: true);
    try {
      final url = await createUrl();
      final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (_disposed) return;
      if (!launched) {
        state = state.copyWith(actionInFlight: false, launchFailed: true);
        return;
      }
      _statusAtFlowStart = state.subscription?.status;
      _cancelAtPeriodEndAtFlowStart = state.subscription?.cancelAtPeriodEnd;
      state = state.copyWith(actionInFlight: false, pendingStripeFlow: true);
    } on ApiException catch (e) {
      if (_disposed) return;
      state = state.copyWith(actionInFlight: false, actionException: e);
    }
  }

  /// Called by the billing screen when the app resumes from the background. No-op unless a
  /// Stripe flow was actually pending (see the class doc comment for the full rationale).
  Future<void> refreshAfterResume() async {
    if (!state.pendingStripeFlow || _disposed) return;
    for (var attempt = 0; attempt < _pollMaxAttempts; attempt++) {
      if (_disposed) return;
      try {
        final subscription = await _service.getSubscription();
        if (_disposed) return;
        state = state.copyWith(subscription: subscription);
        final changed = subscription.status != _statusAtFlowStart ||
            subscription.cancelAtPeriodEnd != _cancelAtPeriodEndAtFlowStart;
        if (changed) break;
      } on ApiException {
        // Swallow: a transient failure mid-poll shouldn't surface as a scary error for what's
        // often an expected no-op (user just looked around and came back, or canceled).
      }
      if (attempt < _pollMaxAttempts - 1) await Future<void>.delayed(_pollInterval);
    }
    if (!_disposed) state = state.copyWith(pendingStripeFlow: false);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final billingControllerProvider = StateNotifierProvider.autoDispose<BillingController, BillingState>((ref) {
  return BillingController(ref);
});
