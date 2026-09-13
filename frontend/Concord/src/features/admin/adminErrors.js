function genericMessage(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

export function mapDisableUserError(error) {
  if (error?.status === 400) {
    return "You can't disable your own account."
  }
  return genericMessage(error)
}

export function mapEnableUserError(error) {
  return genericMessage(error)
}

export function mapSetUserRoleError(error) {
  if (error?.status === 400) {
    return error.message || "You can't change your own role."
  }
  return genericMessage(error)
}

export function mapAdminLoadError(error) {
  return genericMessage(error)
}

export function mapAuditLogLoadError(error) {
  return genericMessage(error)
}

export function mapSubscriptionsLoadError(error) {
  return genericMessage(error)
}
