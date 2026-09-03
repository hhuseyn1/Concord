function genericMessage(error) {
  if (error?.isNetworkError) {
    return "Can't reach the server. Check your connection."
  }
  if (error?.isRateLimited) {
    return 'Too many attempts. Please wait a moment and try again.'
  }
  return error?.message || 'Something went wrong. Please try again.'
}

export function mapGetVoiceTokenError(error) {
  if (error?.status === 403) {
    return "You're not a member of this server."
  }
  if (error?.status === 400) {
    return 'This is not a voice channel.'
  }
  if (error?.status === 404) {
    return 'Your account could not be found.'
  }
  return genericMessage(error)
}

export function mapGetVoiceParticipantsError(error) {
  if (error?.status === 403) {
    return "You're not a member of this server."
  }
  if (error?.status === 400) {
    return 'This is not a voice channel.'
  }
  return genericMessage(error)
}

export function mapVoiceConnectError() {
  return "Couldn't connect to the voice server. Check your connection and try again."
}

export function mapInvoluntaryDisconnectMessage() {
  return "You were disconnected from the call. Check your connection and rejoin if it doesn't reconnect."
}
