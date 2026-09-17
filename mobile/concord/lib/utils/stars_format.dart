library;

import 'package:intl/intl.dart';

import '../api/api.dart';
import '../l10n/app_localizations.dart';
import 'api_error_message.dart';

/// Presentation helpers for Stars. Everything here is derived client-side from
/// what `Stars/Config`, `Stars/Wallet` and `Stars/Transactions` already return -
/// there's no extra backend field behind any of it.

/// `1234` -> `1,234` (grouping follows the app's active locale).
String formatStars(int amount, [String? localeName]) {
  return NumberFormat.decimalPattern(localeName).format(amount);
}

/// Signed for the history list: `+10` / `-500`.
String formatSignedStars(int amount, [String? localeName]) {
  final magnitude = formatStars(amount.abs(), localeName);
  if (amount > 0) return '+$magnitude';
  if (amount < 0) return '-$magnitude';
  return magnitude;
}

/// `0.99` + `"usd"` -> `$0.99`. The API sends Stripe-style lowercase codes; an
/// unrecognized one falls back to `0.99 XYZ` rather than throwing and taking
/// the whole packages list down with it.
String formatPackagePrice(double priceAmount, String currency, [String? localeName]) {
  final code = currency.toUpperCase();
  try {
    return NumberFormat.simpleCurrency(locale: localeName, name: code).format(priceAmount);
  } on Exception {
    return '${priceAmount.toStringAsFixed(2)} $code'.trim();
  }
}

/// Human label for one ledger row, e.g. "Received from alex" / "Premium trial".
String starsTransactionLabel(AppLocalizations l10n, StarTransactionResponse transaction) {
  final name = transaction.counterpartyUsername?.isNotEmpty == true
      ? transaction.counterpartyUsername!
      : l10n.starsUnknownUser;

  return switch (transaction.type) {
    StarTransactionType.chatReward => l10n.starsHistoryChatReward,
    StarTransactionType.transferReceived => l10n.starsHistoryReceivedFrom(name),
    StarTransactionType.transferSent => l10n.starsHistorySentTo(name),
    StarTransactionType.premiumTrialPurchase => l10n.starsHistoryPremiumTrial,
    StarTransactionType.packagePurchase => l10n.starsHistoryPackagePurchase,
    StarTransactionType.unknown => l10n.starsHistoryUnknown,
  };
}

/// Maps a Stars API failure to copy a person can act on, mirroring the web
/// app's `starsErrors.js`. Delegates the generic tail (connectivity/server/
/// fallback) to `apiErrorMessage`, adding only the one Stars-specific case
/// (rate limiting) that generic helper doesn't need to know about.
String _genericStarsError(AppLocalizations l10n, ApiException e) {
  if (e.isRateLimited) return l10n.errorTooManyAttempts;
  return apiErrorMessage(l10n, e);
}

String mapTransferError(AppLocalizations l10n, ApiException e) {
  if (e.isForbidden) return l10n.starsErrorNotFriends;
  if (e.isNotFound) return l10n.starsErrorRecipientNotFound;
  // 409 (conflict) and 402 (payment required) both mean "not enough Stars" here.
  if (e.isConflict || e.statusCode == 402) return l10n.starsErrorInsufficientBalance;
  if (e.isValidationError) {
    return e.message.isNotEmpty ? e.message : l10n.starsErrorTransferInvalid;
  }
  return _genericStarsError(l10n, e);
}

String mapPremiumTrialError(AppLocalizations l10n, ApiException e) {
  if (e.isConflict) return l10n.starsErrorTrialAlreadyActive;
  if (e.statusCode == 402) return l10n.starsErrorInsufficientBalance;
  if (e.isValidationError) {
    return e.message.isNotEmpty ? e.message : l10n.starsErrorInsufficientBalance;
  }
  return _genericStarsError(l10n, e);
}

String mapStarsCheckoutError(AppLocalizations l10n, ApiException e) {
  if (e.isNotFound) return l10n.starsErrorPackageNotFound;
  return _genericStarsError(l10n, e);
}
