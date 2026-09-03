function genericMessage(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

export function mapCreateConversationError(error) {
  if (error?.status === 403) {
    return error?.message || "You can't message this user."
  }
  if (error?.status === 404) {
    return 'That user could not be found.'
  }
  if (error?.status === 400) {
    return "You can't start a conversation with yourself."
  }
  return genericMessage(error)
}

export function mapGetConversationsError(error) {
  return genericMessage(error)
}

export function mapGetDirectMessagesError(error) {
  if (error?.status === 404) {
    return 'This conversation no longer exists.'
  }
  return genericMessage(error)
}

export function mapSendDirectMessageError(error) {
  if (error?.isRateLimited) {
    return "You're sending messages too fast. Wait a moment and try again."
  }
  if (error?.status === 404) {
    if (/message/i.test(error.message ?? '')) {
      return "The message you're replying to no longer exists."
    }
    return 'This conversation no longer exists.'
  }
  if (error?.status === 400) {
    return error.message || 'Messages must be between 1 and 4000 characters.'
  }
  return genericMessage(error)
}

export function mapEditDirectMessageError(error) {
  if (error?.status === 403) {
    return 'You can only edit your own messages.'
  }
  if (error?.status === 404) {
    return 'This message no longer exists.'
  }
  if (error?.status === 400) {
    return error.message || 'Messages must be between 1 and 4000 characters.'
  }
  return genericMessage(error)
}

export function mapDeleteDirectMessageError(error) {
  if (error?.status === 404) {
    return 'This message no longer exists.'
  }
  return genericMessage(error)
}

export function mapToggleReactionError(error) {
  if (error?.status === 404) {
    return 'This message no longer exists.'
  }
  return genericMessage(error)
}

export function mapPinDirectMessageError(error) {
  if (error?.status === 404) {
    return 'This message no longer exists.'
  }
  return genericMessage(error)
}

export function mapForwardDirectMessageError(error) {
  if (error?.status === 403) {
    return error.message || "You can't forward to that conversation."
  }
  if (error?.status === 404) {
    return 'That destination no longer exists.'
  }
  if (error?.status === 400) {
    return error.message || 'Could not forward this message.'
  }
  return genericMessage(error)
}
