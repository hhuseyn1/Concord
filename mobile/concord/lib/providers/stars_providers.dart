import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api.dart';
import 'api_providers.dart';
import 'paged_list_controller.dart';

class StarsState {
  const StarsState({
    this.wallet,
    this.config,
    this.isLoading = true,
    this.loadError,
    this.transferInFlight = false,
    this.trialInFlight = false,
    this.purchasingPackageId,
    this.launchFailed = false,
    this.pendingStripeFlow = false,
  });

  final StarWalletResponse? wallet;
  final StarsConfigResponse? config;

  /// Covers the initial (and retried) load of wallet + config only. Per-action
  /// spinners live in the three fields below so a button can show its own
  /// progress without blanking the whole tab - same split as `BillingState`'s
  /// `isLoading` vs `actionInFlight`.
  final bool isLoading;
  final ApiException? loadError;

  final bool transferInFlight;
  final bool trialInFlight;

  /// Id of the package whose checkout session is being created, so only that
  /// one card's Buy button spins.
  final String? purchasingPackageId;

  /// Set when the checkout URL came back fine but `url_launcher` couldn't open
  /// it at all (no browser). Distinct from an API failure.
  final bool launchFailed;

  /// True once a Stripe checkout URL has been opened externally and we're
  /// waiting to find out whether anything actually happened. See
  /// [StarsController.refreshAfterResume].
  final bool pendingStripeFlow;

  int get balance => wallet?.balance ?? 0;

  StarsState copyWith({
    StarWalletResponse? wallet,
    StarsConfigResponse? config,
    bool? isLoading,
    ApiException? loadError,
    bool clearLoadError = false,
    bool? transferInFlight,
    bool? trialInFlight,
    String? purchasingPackageId,
    bool clearPurchasingPackageId = false,
    bool? launchFailed,
    bool? pendingStripeFlow,
  }) {
    return StarsState(
      wallet: wallet ?? this.wallet,
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      transferInFlight: transferInFlight ?? this.transferInFlight,
      trialInFlight: trialInFlight ?? this.trialInFlight,
      purchasingPackageId:
          clearPurchasingPackageId ? null : (purchasingPackageId ?? this.purchasingPackageId),
      launchFailed: launchFailed ?? this.launchFailed,
      pendingStripeFlow: pendingStripeFlow ?? this.pendingStripeFlow,
    );
  }
}

/// Drives the Stars tab: loads `GET Stars/Config` + `GET Stars/Wallet`, and runs the three spend
/// actions (peer transfer, Stars-funded Premium trial, real-money package purchase).
///
/// ## Action errors are returned, not stashed in state
///
/// [transfer] and [activatePremiumTrial] both return the failing [ApiException] (or `null` on
/// success) instead of parking it on [StarsState]. Both are driven from a transient form (a bottom
/// sheet / a dialog) that owns its own inline error line and has to decide whether to stay open,
/// which is awkward to express through shared state - and a stale error outliving the sheet that
/// produced it would be worse. Checkout, which has no form, keeps its failure in state like
/// `BillingController` does.
///
/// ## Why the purchase flow polls a *purchase status* on resume
///
/// Same starting point as `BillingController`: `Stars/Purchases/CheckoutSession` bakes a fixed,
/// backend-configured success/cancel URL pointing at the web app into the Stripe session, so
/// Stripe can never redirect back into this app, and resuming from the background is the only
/// signal we get that the user might be done.
///
/// Unlike the subscription flow, `CreateCheckoutSession`'s response carries the purchase id
/// alongside the checkout `Url` (see `CreateStarsCheckoutSessionResponse` /
/// `StarsService.CreateCheckoutSessionAsync` on the backend), so [refreshAfterResume] polls the
/// exact `GET Stars/Purchases/{purchaseId}/Status` endpoint instead of inferring completion from
/// a wallet-balance delta. A `Completed` status triggers one [refreshWallet] call to pick up the
/// credited balance; `Pending` keeps polling within the bounded window; anything else (`Failed`/
/// `Canceled`, or the window running out) just stops - the user may have abandoned checkout or
/// simply switched apps and come back, which is a normal, silent outcome, not an error.
class StarsController extends StateNotifier<StarsState> {
  StarsController(this._ref) : super(const StarsState()) {
    unawaited(load());
  }

  final Ref _ref;
  bool _disposed = false;

  /// Id of the purchase a checkout flow was launched for, so [refreshAfterResume] knows what to
  /// poll `GET Stars/Purchases/{purchaseId}/Status` with.
  String? _pendingPurchaseId;

  static const _pollInterval = Duration(seconds: 2);
  // ~16s bounded window, same reasoning as BillingController's: long enough for an in-flight
  // webhook to land, short enough not to leave the user watching nothing happen.
  static const _pollMaxAttempts = 8;

  StarsService get _service => _ref.read(starsServiceProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearLoadError: true);
    try {
      // Config is static server-side constants and the wallet is per-user; neither depends on the
      // other, so they go out together.
      final results = await Future.wait([_service.getConfig(), _service.getWallet()]);
      if (_disposed) return;
      state = state.copyWith(
        config: results[0] as StarsConfigResponse,
        wallet: results[1] as StarWalletResponse,
        isLoading: false,
      );
    } on ApiException catch (e) {
      if (_disposed) return;
      state = state.copyWith(isLoading: false, loadError: e);
    }
  }

  /// Re-reads just the wallet (balance/trial flags). Used after a spend action and by the
  /// resume poll; never touches [StarsState.isLoading] so the tab doesn't flash.
  Future<void> refreshWallet() async {
    try {
      final wallet = await _service.getWallet();
      if (_disposed) return;
      state = state.copyWith(wallet: wallet);
    } on ApiException {
      // A failed background refresh leaves the last known wallet on screen, which is strictly
      // better than replacing a working balance with an error.
    }
  }

  /// Sends Stars to a friend. Returns `null` on success, or the [ApiException] to show inline.
  ///
  /// [idempotencyKey] must be the *same* key across retries of one user attempt - the caller owns
  /// it (see `newIdempotencyKey`) precisely so a retry after a timeout can't double-spend.
  Future<ApiException?> transfer({
    required String recipientUserId,
    required int amount,
    required String idempotencyKey,
  }) async {
    if (state.transferInFlight) return null;
    state = state.copyWith(transferInFlight: true);
    try {
      final result = await _service.transfer(
        recipientUserId: recipientUserId,
        amount: amount,
        idempotencyKey: idempotencyKey,
      );
      if (_disposed) return null;
      // The response carries the authoritative post-transfer balance, so there's no need to
      // round-trip the wallet again just to update the number on screen.
      state = state.copyWith(
        transferInFlight: false,
        wallet: state.wallet?.copyWith(balance: result.balance),
      );
      return null;
    } on ApiException catch (e) {
      if (!_disposed) state = state.copyWith(transferInFlight: false);
      return e;
    }
  }

  /// Spends Stars on the Premium trial. Returns `null` on success, or the [ApiException].
  Future<ApiException?> activatePremiumTrial(String idempotencyKey) async {
    if (state.trialInFlight) return null;
    state = state.copyWith(trialInFlight: true);
    try {
      final result = await _service.activatePremiumTrial(idempotencyKey);
      if (_disposed) return null;
      state = state.copyWith(
        trialInFlight: false,
        wallet: state.wallet?.copyWith(
          balance: result.balance,
          premiumTrialActive: true,
          premiumTrialExpiresAt: result.premiumTrialExpiresAt,
          hasActivePremium: true,
        ),
      );
      return null;
    } on ApiException catch (e) {
      if (!_disposed) state = state.copyWith(trialInFlight: false);
      return e;
    }
  }

  /// Buy-button handler for one Stars package: creates a Stripe Checkout session and opens it in
  /// the external browser (never an in-app WebView - same distribution-compliance note as
  /// `BillingController.subscribe`). Returns the [ApiException] if the session couldn't be created.
  Future<ApiException?> buyPackage(String packageId) async {
    if (state.purchasingPackageId != null) return null; // guard duplicate taps
    state = state.copyWith(purchasingPackageId: packageId, launchFailed: false);
    try {
      final session = await _service.createCheckoutSession(packageId);
      final launched = await launchUrl(Uri.parse(session.url), mode: LaunchMode.externalApplication);
      if (_disposed) return null;
      if (!launched) {
        state = state.copyWith(clearPurchasingPackageId: true, launchFailed: true);
        return null;
      }
      _pendingPurchaseId = session.purchaseId;
      state = state.copyWith(clearPurchasingPackageId: true, pendingStripeFlow: true);
      return null;
    } on ApiException catch (e) {
      if (!_disposed) state = state.copyWith(clearPurchasingPackageId: true);
      return e;
    }
  }

  /// Called by the Stars tab when the app comes back to the foreground. No-op unless a checkout
  /// was actually launched - see the class doc comment for the polling strategy.
  Future<void> refreshAfterResume() async {
    if (!state.pendingStripeFlow || _disposed) return;
    final purchaseId = _pendingPurchaseId;
    if (purchaseId == null) {
      state = state.copyWith(pendingStripeFlow: false, launchFailed: false);
      return;
    }
    for (var attempt = 0; attempt < _pollMaxAttempts; attempt++) {
      if (_disposed) return;
      try {
        final result = await _service.getPurchaseStatus(purchaseId);
        if (_disposed) return;
        if (result.status == StarPurchaseStatus.completed) {
          await refreshWallet();
          break;
        }
        if (result.status != StarPurchaseStatus.pending) break;
      } on ApiException {
        // Swallowed on purpose: a transient failure mid-poll shouldn't surface as an error for
        // what is very often an expected no-op.
      }
      if (attempt < _pollMaxAttempts - 1) await Future<void>.delayed(_pollInterval);
    }
    if (!_disposed) {
      _pendingPurchaseId = null;
      state = state.copyWith(pendingStripeFlow: false, launchFailed: false);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// `autoDispose`, like `billingControllerProvider`: the wallet is per-account data, so tearing it
/// down when Settings (its only host) goes away means a different account can never be shown a
/// stale balance - at the cost of one reload the next time Settings is opened.
final starsControllerProvider =
    StateNotifierProvider.autoDispose<StarsController, StarsState>((ref) {
  return StarsController(ref);
});

/// Ledger history. A plain [PagedListController] rather than another field on [StarsState]: it's an
/// ordinary load-more list with no interplay with the wallet actions beyond being invalidated
/// after one, and reusing the shared controller gets paging/retry/append for free (same wiring as
/// `friendsListControllerProvider`).
final starsTransactionsControllerProvider = StateNotifierProvider.autoDispose<
    PagedListController<StarTransactionResponse>, PagedListState<StarTransactionResponse>>((ref) {
  final service = ref.watch(starsServiceProvider);
  return PagedListController<StarTransactionResponse>(
    ({required int page, required int pageSize}) => service.getTransactions(page: page, pageSize: pageSize),
    pageSize: 20,
  );
});
