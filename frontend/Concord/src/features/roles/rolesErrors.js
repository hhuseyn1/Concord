function genericMessage(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

function mapForbidden(error) {
  const message = typeof error?.message === 'string' ? error.message.toLowerCase() : ''

  if (message.includes('ranked at or above')) {
    return "You can't change a role ranked at or above your own highest role."
  }
  if (message.includes('default role')) {
    return "The @everyone role can't be renamed, deleted, or assigned - only its permissions can change."
  }
  if (message.includes('lack the')) {
    return error.message
  }
  return "You don't have permission to manage roles on this server."
}

export function mapCreateRoleError(error) {
  if (error?.status === 403) {
    return mapForbidden(error)
  }
  if (error?.status === 400) {
    return error.message || 'That role name or permission set is not valid.'
  }
  return genericMessage(error)
}

export function mapUpdateRoleError(error) {
  if (error?.status === 403) {
    return mapForbidden(error)
  }
  if (error?.status === 404) {
    return 'That role no longer exists.'
  }
  if (error?.status === 400) {
    return error.message || 'That role name or permission set is not valid.'
  }
  return genericMessage(error)
}

export function mapDeleteRoleError(error) {
  if (error?.status === 403) {
    return mapForbidden(error)
  }
  if (error?.status === 404) {
    return 'That role no longer exists.'
  }
  return genericMessage(error)
}

export function mapAssignRoleError(error) {
  if (error?.status === 403) {
    return mapForbidden(error)
  }
  if (error?.status === 404) {
    return 'That role or member no longer exists.'
  }
  if (error?.status === 400) {
    return "You can't change your own roles."
  }
  return genericMessage(error)
}
