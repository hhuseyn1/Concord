import '../../api/api.dart';

String mapLoginError(ApiException error) {
  if (error.isNetworkError) {
    return "Can't reach the server. Check your connection.";
  }
  if (error.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  if (error.isLikelyAccountLockout) {
    return 'Your account is temporarily locked. Try again in a few minutes.';
  }
  if (error.isUnauthorized || error.isValidationError) {
    return error.message.isNotEmpty ? error.message : 'Invalid email or password';
  }
  return error.message.isNotEmpty ? error.message : 'Something went wrong. Please try again.';
}

String mapTwoFactorLoginError(ApiException error) {
  if (error.isNetworkError) {
    return "Can't reach the server. Check your connection.";
  }
  if (error.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  if (error.isLikelyAccountLockout) {
    return 'Your account is temporarily locked. Try again in a few minutes.';
  }
  if (error.isUnauthorized) {
    return 'That sign-in attempt expired. Go back and enter your password again.';
  }
  if (error.isValidationError) {
    return 'That code is not valid. Check your authenticator app, or use a recovery code.';
  }
  return error.message.isNotEmpty ? error.message : 'Something went wrong. Please try again.';
}

String mapRegisterError(ApiException error) {
  if (error.isNetworkError) {
    return "Can't reach the server. Check your connection.";
  }
  if (error.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  if (error.isConflict) {
    return 'An account with that email already exists.';
  }
  return error.message.isNotEmpty ? error.message : 'Something went wrong. Please try again.';
}
