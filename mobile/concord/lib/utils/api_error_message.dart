library;

import '../api/api.dart';
import '../l10n/app_localizations.dart';

/// Maps an [ApiException] to user-facing copy, insulating the UI from
/// low-level exception internals - a `SocketException`'s raw text can
/// include the request host/port (e.g. a dev `localhost` API URL), and
/// showing that verbatim reads as a bug rather than a plain "you're
/// offline". A connectivity failure always shows
/// [AppLocalizations.errorCouldNotReachServer] regardless of what the
/// underlying exception said; a 5xx falls back to
/// [AppLocalizations.errorServerTrouble] rather than a raw server body
/// that's rarely written for end users. Anything else falls through to the
/// exception's own message, which for a 4xx is normally a real,
/// already-user-facing string the backend sent on purpose.
String apiErrorMessage(AppLocalizations l10n, ApiException e) {
  if (e.isConnectivityError) return l10n.errorCouldNotReachServer;
  if (e.message.isNotEmpty) return e.message;
  if (e.isServerError) return l10n.errorServerTrouble;
  return l10n.errorSomethingWentWrong;
}
