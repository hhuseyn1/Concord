const PRESENCE_TO_AVATAR_PROP = {
  Online: 'online',
  Idle: 'idle',
  DoNotDisturb: 'dnd',
  Invisible: 'offline',
  Offline: 'offline',
}

export function toAvatarPresence(status) {
  return PRESENCE_TO_AVATAR_PROP[status] ?? 'offline'
}

const PRESENCE_ORDER = { Online: 0, Idle: 1, DoNotDisturb: 2, Invisible: 3, Offline: 3 }

export function presenceSortWeight(status) {
  return PRESENCE_ORDER[status] ?? PRESENCE_ORDER.Offline
}
