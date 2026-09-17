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

  final bool isLoading;
  final ApiException? loadError;

  final bool transferInFlight;
  final bool trialInFlight;

  final String? purchasingPackageId;

  final bool launchFailed;

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

class StarsController extends StateNotifier<StarsState> {
  StarsController(this._ref) : super(const StarsState()) {
    unawaited(load());
  }

  final Ref _ref;
  bool _disposed = false;

  String? _pendingPurchaseId;

  static const _pollInterval = Duration(seconds: 2);
  static const _pollMaxAttempts = 8;

  StarsService get _service => _ref.read(starsServiceProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearLoadError: true);
    try {
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

  Future<void> refreshWallet() async {
    try {
      final wallet = await _service.getWallet();
      if (_disposed) return;
      state = state.copyWith(wallet: wallet);
    } on ApiException {
    }
  }

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

  Future<ApiException?> buyPackage(String packageId) async {
    if (state.purchasingPackageId != null) return null;
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

final starsControllerProvider =
    StateNotifierProvider.autoDispose<StarsController, StarsState>((ref) {
  return StarsController(ref);
});

final starsTransactionsControllerProvider = StateNotifierProvider.autoDispose<
    PagedListController<StarTransactionResponse>, PagedListState<StarTransactionResponse>>((ref) {
  final service = ref.watch(starsServiceProvider);
  return PagedListController<StarTransactionResponse>(
    ({required int page, required int pageSize}) => service.getTransactions(page: page, pageSize: pageSize),
    pageSize: 20,
  );
});
