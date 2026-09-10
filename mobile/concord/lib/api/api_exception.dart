/// Coarse-grained classification of [ApiException]s so callers/UI can tell
/// a connectivity failure (offline, DNS, dropped connection, timeout) apart
/// from a request that reached the server but failed there, apart from a
/// client/validation error, without re-deriving that logic at every call
/// site. Prefer the `is*` getters below over comparing [kind] directly.
enum ApiErrorKind { network, timeout, client, server, unknown }

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message, {this.twoFactorToken});

  final int statusCode;

  final String? twoFactorToken;

  final String message;

  bool get isUnauthorized => statusCode == 401;

  bool get isForbidden => statusCode == 403;

  bool get isNotFound => statusCode == 404;

  bool get isConflict => statusCode == 409;

  bool get isValidationError => statusCode == 400;

  bool get isRateLimited => statusCode == 429;

  bool get isServerError => statusCode >= 500;

  bool get isNetworkError => statusCode == networkErrorStatusCode;

  /// True when the request never got a response within the client-side
  /// timeout (see `ApiClient`'s ~15s `.timeout(...)` calls), as opposed to
  /// a connection that failed outright ([isNetworkError]).
  bool get isTimeout => statusCode == timeoutStatusCode;

  /// True for any connectivity-related failure - offline, DNS/connection
  /// failure, or a bounded client-side timeout - as opposed to a request
  /// that reached the server and failed there ([isServerError]) or a
  /// client/validation error.
  bool get isConnectivityError => isNetworkError || isTimeout;

  ApiErrorKind get kind {
    if (isTimeout) return ApiErrorKind.timeout;
    if (isNetworkError) return ApiErrorKind.network;
    if (isTwoFactorRequired) return ApiErrorKind.client;
    if (isServerError) return ApiErrorKind.server;
    if (statusCode >= 400) return ApiErrorKind.client;
    return ApiErrorKind.unknown;
  }

  bool get isLikelyAccountLockout =>
      statusCode == 401 &&
      message.contains('exceeded the number of allowed authentication attempts');

  static const int twoFactorRequiredStatusCode = -1;

  /// Sentinel status code for connection-level failures (no response was
  /// ever received - offline, DNS failure, connection reset, etc.).
  static const int networkErrorStatusCode = 0;

  /// Sentinel status code for a request that hit the client-side timeout
  /// before a response came back.
  static const int timeoutStatusCode = -2;

  bool get isTwoFactorRequired => statusCode == twoFactorRequiredStatusCode;

  @override
  String toString() => 'ApiException($statusCode, $message)';
}
