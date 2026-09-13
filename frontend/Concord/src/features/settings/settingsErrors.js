function genericMessage(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

export function mapUpdateProfileError(error) {
  if (error?.status === 409) {
    return 'That username is already taken. Try another one.'
  }
  if (error?.status === 400) {
    return error.message || 'Check that your name, surname, and username are valid.'
  }
  return genericMessage(error)
}

export function mapAvatarUploadError(error) {
  if (error?.status === 400) {
    return error.message || "That image can't be used - check the file type and size (max 5 MB)."
  }
  return genericMessage(error)
}

export function mapChangePasswordError(error) {
  if (error?.status === 401) {
    return 'Current password is incorrect.'
  }
  if (error?.status === 400) {
    return error.message || 'Check that your new password is at least 8 characters.'
  }
  return genericMessage(error)
}

export function mapDeleteAccountError(error) {
  if (error?.status === 401) {
    return 'Current password is incorrect.'
  }
  if (error?.status === 400) {
    return error.message || 'Current password is incorrect.'
  }
  return genericMessage(error)
}

export function mapSessionActionError(error) {
  if (error?.status === 404) {
    return 'That session no longer exists - it may have already been signed out.'
  }
  return genericMessage(error)
}

export function mapCheckoutSessionError(error) {
  return genericMessage(error)
}

export function mapPortalSessionError(error) {
  return genericMessage(error)
}
