const LOCKOUT_MESSAGE_SUBSTRING = 'exceeded the number of allowed authentication attempts'

export function mapLoginError(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  if (typeof error?.message === 'string' && error.message.includes(LOCKOUT_MESSAGE_SUBSTRING)) {
    return 'Your account is temporarily locked. Try again in a few minutes.'
  }
  if (error?.status === 401 || error?.status === 400) {
    return error.message || 'Invalid email or password'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

export function mapRegisterError(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  if (error?.status === 409) {
    return 'An account with that email already exists.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

export function mapForgotPasswordError(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

export function mapResetPasswordError(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  if (error?.status === 401) {
    return 'This reset link is invalid or has expired. Request a new one.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

export function mapTwoFactorLoginError(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  if (typeof error?.message === 'string' && error.message.includes(LOCKOUT_MESSAGE_SUBSTRING)) {
    return 'Your account is temporarily locked. Try again in a few minutes.'
  }
  if (error?.status === 401) {
    return 'That sign-in attempt expired. Go back and enter your password again.'
  }
  if (error?.status === 400) {
    return 'That code is not valid. Check your authenticator app, or use a recovery code.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

export function mapTwoFactorSetupError(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  if (error?.status === 409) {
    return 'Two-factor authentication is already enabled on this account.'
  }
  if (error?.status === 400) {
    const message = typeof error.message === 'string' ? error.message.toLowerCase() : ''
    if (message.includes('password')) {
      return 'That password is not correct.'
    }
    if (message.includes('start two-factor setup')) {
      return 'Start setup again - the previous code expired.'
    }
    return 'That code is not valid. Check your authenticator app and try again.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

export function mapVerifyEmailError(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  return 'This verification link is invalid or has expired.'
}

export function isUnverifiedEmailError(error) {
  return typeof error?.message === 'string' && error.message.includes('verify your email address')
}

export function mapQrLoginApprovalError(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  if (error?.status === 404) {
    return 'That sign-in code is invalid or has expired. Ask for a new one.'
  }
  if (error?.status === 403) {
    return 'That sign-in request has already been handled.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}
