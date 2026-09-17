import '../../api/api.dart';
import '../../l10n/app_localizations.dart';

String _fallbackMessage(AppLocalizations l10n, ApiException error) {
  if (error.isConnectivityError) {
    return l10n.errorCouldNotReachServer;
  }
  if (error.isServerError) {
    return l10n.errorServerTrouble;
  }
  return l10n.errorSomethingWentWrong;
}

String mapLoginError(AppLocalizations l10n, ApiException error) {
  if (error.isConnectivityError) {
    return l10n.errorCantReachServer;
  }
  if (error.isRateLimited) {
    return l10n.errorTooManyAttempts;
  }
  if (error.isLikelyAccountLockout) {
    return l10n.errorAccountLocked;
  }
  if (error.isUnauthorized || error.isValidationError) {
    return error.message.isNotEmpty ? error.message : l10n.errorInvalidEmailPassword;
  }
  return error.message.isNotEmpty ? error.message : _fallbackMessage(l10n, error);
}

String mapTwoFactorLoginError(AppLocalizations l10n, ApiException error) {
  if (error.isConnectivityError) {
    return l10n.errorCantReachServer;
  }
  if (error.isRateLimited) {
    return l10n.errorTooManyAttempts;
  }
  if (error.isLikelyAccountLockout) {
    return l10n.errorAccountLocked;
  }
  if (error.isUnauthorized) {
    return l10n.errorSignInExpired;
  }
  if (error.isValidationError) {
    return l10n.errorInvalidCode;
  }
  return error.message.isNotEmpty ? error.message : _fallbackMessage(l10n, error);
}

String mapRegisterError(AppLocalizations l10n, ApiException error) {
  if (error.isConnectivityError) {
    return l10n.errorCantReachServer;
  }
  if (error.isRateLimited) {
    return l10n.errorTooManyAttempts;
  }
  if (error.isConflict) {
    return error.message.toLowerCase().contains('username') ? l10n.usernameTakenError : l10n.errorAccountExists;
  }
  return error.message.isNotEmpty ? error.message : _fallbackMessage(l10n, error);
}
