library;

import '../api/api.dart';
import '../l10n/app_localizations.dart';

String apiErrorMessage(AppLocalizations l10n, ApiException e) {
  if (e.isConnectivityError) return l10n.errorCouldNotReachServer;
  if (e.message.isNotEmpty) return e.message;
  if (e.isServerError) return l10n.errorServerTrouble;
  return l10n.errorSomethingWentWrong;
}
