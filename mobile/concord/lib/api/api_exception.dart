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

  bool get isTimeout => statusCode == timeoutStatusCode;

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

  static const int networkErrorStatusCode = 0;

  static const int timeoutStatusCode = -2;

  bool get isTwoFactorRequired => statusCode == twoFactorRequiredStatusCode;

  @override
  String toString() => 'ApiException($statusCode, $message)';
}
