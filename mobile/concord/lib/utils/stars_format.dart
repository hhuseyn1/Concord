library;

import 'package:intl/intl.dart';

import '../api/api.dart';
import '../l10n/app_localizations.dart';
import 'api_error_message.dart';


String formatStars(int amount, [String? localeName]) {
  return NumberFormat.decimalPattern(localeName).format(amount);
}

String formatSignedStars(int amount, [String? localeName]) {
  final magnitude = formatStars(amount.abs(), localeName);
  if (amount > 0) return '+$magnitude';
  if (amount < 0) return '-$magnitude';
  return magnitude;
}

String formatPackagePrice(double priceAmount, String currency, [String? localeName]) {
  final code = currency.toUpperCase();
  try {
    return NumberFormat.simpleCurrency(locale: localeName, name: code).format(priceAmount);
  } on Exception {
    return '${priceAmount.toStringAsFixed(2)} $code'.trim();
  }
}

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

String _genericStarsError(AppLocalizations l10n, ApiException e) {
  if (e.isRateLimited) return l10n.errorTooManyAttempts;
  return apiErrorMessage(l10n, e);
}

String mapTransferError(AppLocalizations l10n, ApiException e) {
  if (e.isForbidden) return l10n.starsErrorNotFriends;
  if (e.isNotFound) return l10n.starsErrorRecipientNotFound;
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
