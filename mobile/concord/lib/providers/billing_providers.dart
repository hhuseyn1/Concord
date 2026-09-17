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

  final bool actionInFlight;

  final ApiException? actionException;

  final bool launchFailed;

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

class BillingController extends StateNotifier<BillingState> {
  BillingController(this._ref) : super(const BillingState()) {
    unawaited(load());
  }

  final Ref _ref;
  bool _disposed = false;

  SubscriptionStatus? _statusAtFlowStart;
  bool? _cancelAtPeriodEndAtFlowStart;

  static const _pollInterval = Duration(seconds: 2);
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

  Future<void> subscribe() => _launchStripeFlow(() async => (await _service.createCheckoutSession()).url);

  Future<void> manage() => _launchStripeFlow(() async => (await _service.createPortalSession()).url);

  Future<void> _launchStripeFlow(Future<String> Function() createUrl) async {
    if (state.actionInFlight) return;
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
