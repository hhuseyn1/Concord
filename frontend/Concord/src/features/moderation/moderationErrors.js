function genericMessage(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

function isHierarchyError(error) {
  return typeof error?.message === 'string' && error.message.toLowerCase().includes('ranked at or above')
}

export function mapBanMemberError(error) {
  if (error?.status === 403) {
    return isHierarchyError(error)
      ? "You can't ban someone ranked at or above your highest role."
      : 'You need the Ban Members permission to ban people from this server.'
  }
  if (error?.status === 409) {
    return 'That user is already banned.'
  }
  if (error?.status === 400) {
    return error.message || "You can't ban yourself."
  }
  return genericMessage(error)
}

export function mapUnbanUserError(error) {
  if (error?.status === 403) {
    return 'You need the Ban Members permission to lift bans.'
  }
  if (error?.status === 404) {
    return 'That user is no longer banned.'
  }
  return genericMessage(error)
}

export function mapGetBansError(error) {
  if (error?.status === 403) {
    return 'You need the Ban Members permission to view the ban list.'
  }
  return genericMessage(error)
}

export function mapMuteMemberError(error) {
  if (error?.status === 403) {
    return isHierarchyError(error)
      ? "You can't mute someone ranked at or above your highest role."
      : 'You need the Mute Members permission to do that.'
  }
  if (error?.status === 400) {
    return error.message || "You can't mute yourself."
  }
  if (error?.status === 404) {
    return 'That user is no longer a member of this server.'
  }
  return genericMessage(error)
}

export function mapTimeoutMemberError(error) {
  if (error?.status === 403) {
    return isHierarchyError(error)
      ? "You can't time out someone ranked at or above your highest role."
      : 'You need the Timeout Members permission to do that.'
  }
  if (error?.status === 400) {
    return error.message || 'That timeout duration is not valid (max 28 days).'
  }
  if (error?.status === 404) {
    return 'That user is no longer a member of this server.'
  }
  return genericMessage(error)
}
