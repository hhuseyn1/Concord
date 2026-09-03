function genericMessage(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

export function mapGetChannelsError(error) {
  if (error?.status === 403) {
    return "You're not a member of this server."
  }
  return genericMessage(error)
}

export function mapCreateChannelError(error) {
  if (error?.status === 403) {
    return 'Only the server owner can create channels.'
  }
  if (error?.status === 400) {
    return error.message || 'That channel name is not valid.'
  }
  return genericMessage(error)
}

export function mapRenameChannelError(error) {
  if (error?.status === 403) {
    return 'Only the server owner can rename channels.'
  }
  if (error?.status === 400) {
    return error.message || 'That channel name is not valid.'
  }
  if (error?.status === 404) {
    return 'This channel no longer exists.'
  }
  return genericMessage(error)
}

export function mapDeleteChannelError(error) {
  if (error?.status === 403) {
    return 'Only the server owner can delete channels.'
  }
  if (error?.status === 404) {
    return 'This channel no longer exists.'
  }
  return genericMessage(error)
}
