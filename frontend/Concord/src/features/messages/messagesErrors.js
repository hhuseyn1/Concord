function genericMessage(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

export function mapGetMessagesError(error) {
  if (error?.status === 403) {
    return "You're not a member of this server."
  }
  return genericMessage(error)
}

export function mapSendMessageError(error) {
  if (error?.isRateLimited) {
    return "You're sending messages too fast. Wait a moment and try again."
  }
  if (error?.status === 403) {
    return "You're not a member of this server."
  }
  if (error?.status === 400) {
    return error.message || 'Messages must be between 1 and 4000 characters.'
  }
  if (error?.status === 404) {
    if (/message/i.test(error.message ?? '')) {
      return "The message you're replying to no longer exists."
    }
    return 'Your account could not be found.'
  }
  return genericMessage(error)
}

export function mapEditMessageError(error) {
  if (error?.status === 403) {
    return typeof error.message === 'string' && error.message.toLowerCase().includes('author')
      ? 'You can only edit your own messages.'
      : "You're not a member of this server."
  }
  if (error?.status === 404) {
    return 'This message no longer exists.'
  }
  if (error?.status === 400) {
    return error.message || 'Messages must be between 1 and 4000 characters.'
  }
  return genericMessage(error)
}

export function mapDeleteMessageError(error) {
  if (error?.status === 403) {
    return "You're not a member of this server."
  }
  if (error?.status === 404) {
    return 'This message no longer exists.'
  }
  return genericMessage(error)
}

export function mapToggleReactionError(error) {
  if (error?.status === 403) {
    return "You're not a member of this server."
  }
  if (error?.status === 404) {
    return 'This message no longer exists.'
  }
  return genericMessage(error)
}

export function mapPinMessageError(error) {
  if (error?.status === 403) {
    return error.message || 'Only the server owner or the message author can pin this.'
  }
  if (error?.status === 404) {
    return 'This message no longer exists.'
  }
  return genericMessage(error)
}

export function mapForwardMessageError(error) {
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

export function mapAttachmentUploadError(error) {
  if (error?.status === 400) {
    return error.message || "That file can't be attached - check the file type and size (max 25 MB)."
  }
  return genericMessage(error)
}
