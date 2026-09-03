function genericMessage(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

export function mapStartCallError(error) {
  if (error?.status === 404) {
    return "This conversation couldn't be found."
  }
  return genericMessage(error)
}

export function mapCallActionError(error) {
  if (error?.status === 409) {
    return 'This call has already been answered.'
  }
  if (error?.status === 404) {
    return 'This call no longer exists.'
  }
  return genericMessage(error)
}
