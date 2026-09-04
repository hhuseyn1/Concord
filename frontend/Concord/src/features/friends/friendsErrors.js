function genericMessage(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

export function mapSendFriendRequestError(error) {
  if (error?.status === 400) {
    return "You can't send a friend request to yourself."
  }
  if (error?.status === 403) {
    return "You can't send a request to this user."
  }
  if (error?.status === 404) {
    return 'That user could not be found.'
  }
  if (error?.status === 409) {
    return 'You already have a pending request (or friendship) with this user.'
  }
  return genericMessage(error)
}

export function mapRequestActionError(error) {
  if (error?.status === 404) {
    return 'That friend request no longer exists - it may have already been handled.'
  }
  return genericMessage(error)
}

export function mapBlockError(error) {
  if (error?.status === 400) {
    return "You can't block yourself."
  }
  if (error?.status === 404) {
    return 'That user could not be found.'
  }
  if (error?.status === 409) {
    return "You've already blocked this user."
  }
  return genericMessage(error)
}

export function mapUnblockError(error) {
  if (error?.status === 404) {
    return "This user isn't currently blocked."
  }
  return genericMessage(error)
}
