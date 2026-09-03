const STORAGE_KEY = 'concord.desktopNotifications.enabled'

export function isDesktopNotificationsEnabled() {
  try {
    return localStorage.getItem(STORAGE_KEY) === 'true'
  } catch {
    return false
  }
}

export function setDesktopNotificationsEnabled(enabled) {
  try {
    localStorage.setItem(STORAGE_KEY, enabled ? 'true' : 'false')
  } catch {
  }
}

export function getNotificationPermission() {
  if (typeof Notification === 'undefined') return 'unsupported'
  return Notification.permission
}

export async function requestNotificationPermission() {
  if (typeof Notification === 'undefined') return 'unsupported'
  return Notification.requestPermission()
}

export function showDesktopNotification({ title, body, icon, onClick }) {
  if (!isDesktopNotificationsEnabled()) return
  if (getNotificationPermission() !== 'granted') return
  if (document.visibilityState === 'visible') return

  try {
    const notification = new Notification(title, { body, icon });
    notification.onclick = () => {
      window.focus()
      onClick?.()
      notification.close()
    }
  } catch (error) {
    console.error('Failed to show a desktop notification', error)
  }
}
