function genericMessage(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

export function mapCreateServerError(error) {
  if (error?.status === 400) {
    return error.message || 'That server name is not valid.'
  }
  return genericMessage(error)
}

export function mapServerIconUploadError(error) {
  if (error?.status === 400) {
    return error.message || "That image can't be used — check the file type and size (max 5 MB)."
  }
  return genericMessage(error)
}

export function mapJoinServerError(error) {
  if (error?.status === 404) {
    return 'That invite code is invalid, expired, or no longer works.'
  }
  return genericMessage(error)
}

export function mapLeaveServerError(error) {
  if (error?.status === 403) {
    return typeof error.message === 'string' && error.message.toLowerCase().includes('owner')
      ? "Owners can't leave their own server — transfer ownership first."
      : "You're not a member of this server."
  }
  if (error?.status === 404) {
    return 'This server no longer exists.'
  }
  return genericMessage(error)
}

export function mapDeleteServerError(error) {
  if (error?.status === 403) {
    return 'Only the server owner can delete this server.'
  }
  if (error?.status === 404) {
    return 'This server no longer exists.'
  }
  return genericMessage(error)
}

export function mapRemoveMemberError(error) {
  if (error?.status === 403) {
    return typeof error.message === 'string' && error.message.toLowerCase().includes('ranked at or above')
      ? "You can't remove someone ranked at or above your highest role."
      : 'You need the Kick Members permission to remove members.'
  }
  if (error?.status === 400) {
    return "You can't remove yourself this way — use Leave Server instead."
  }
  return genericMessage(error)
}

export function mapUpdateServerError(error) {
  if (error?.status === 403) {
    return 'You need the Manage Server permission to edit this server.'
  }
  if (error?.status === 400) {
    return error.message || 'That server name is not valid.'
  }
  return genericMessage(error)
}

export function mapTransferOwnershipError(error) {
  if (error?.status === 403) {
    return error.message || "You're not the owner of this server, or the selected user isn't a member."
  }
  return genericMessage(error)
}

export function mapGenerateInviteError(error) {
  if (error?.status === 403) {
    return 'You need the Manage Invites permission to create invites.'
  }
  if (error?.status === 400) {
    return error.message || 'Could not generate an invite with those settings.'
  }
  return genericMessage(error)
}

export function mapListInvitesError(error) {
  if (error?.status === 403) {
    return 'You need the Manage Invites permission to view invites.'
  }
  return genericMessage(error)
}
