export const PERMISSIONS = {
  ViewChannels: 1,
  SendMessages: 2,
  ManageMessages: 4,
  ManageChannels: 8,
  ManageServer: 16,
  ManageRoles: 32,
  ManageInvites: 64,
  KickMembers: 128,
  BanMembers: 256,
  MuteMembers: 512,
  ModerateMembers: 1024,
  Connect: 2048,
  Speak: 4096,
  Administrator: 8192,
}

export const PERMISSION_GROUPS = [
  { id: 'general', keys: ['ViewChannels', 'SendMessages', 'Connect', 'Speak'] },
  { id: 'moderation', keys: ['ManageMessages', 'KickMembers', 'BanMembers', 'MuteMembers', 'ModerateMembers'] },
  { id: 'management', keys: ['ManageChannels', 'ManageInvites', 'ManageRoles', 'ManageServer', 'Administrator'] },
]

export const RESERVED_PERMISSIONS = []

export function hasPermission(permissions, flag) {
  const value = typeof flag === 'string' ? PERMISSIONS[flag] : flag
  if (!value) return false
  const total = Number(permissions) || 0
  if (Math.floor(total / PERMISSIONS.Administrator) % 2 === 1) return true
  return Math.floor(total / value) % 2 === 1
}

export function togglePermission(permissions, flag, enabled) {
  const value = typeof flag === 'string' ? PERMISSIONS[flag] : flag
  const total = Number(permissions) || 0
  if (!value) return total
  const isSet = Math.floor(total / value) % 2 === 1
  if (enabled && !isSet) return total + value
  if (!enabled && isSet) return total - value
  return total
}
