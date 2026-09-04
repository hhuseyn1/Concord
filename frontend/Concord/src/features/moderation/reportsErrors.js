function genericMessage(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

export function mapCreateReportError(error) {
  if (error?.status === 400) {
    return error.message || "You can't report yourself, and a reason is required."
  }
  if (error?.status === 404) {
    return "That message or user no longer exists - it may have already been deleted."
  }
  if (error?.status === 403) {
    return "You no longer have access to that message."
  }
  return genericMessage(error)
}

export function mapGetReportsError(error) {
  return genericMessage(error)
}

export function mapReviewReportError(error) {
  if (error?.status === 409) {
    return 'Another admin already reviewed this report.'
  }
  if (error?.status === 404) {
    return 'That report no longer exists.'
  }
  return genericMessage(error)
}
