// "Blink blink" the tab title so an unread message/friend request is noticeable even when Concord
// is just a background tab, not the focused window - a browser-notification permission doesn't
// help there (it may be denied, or the user may just not want popups), but a flashing title costs
// nothing to notice out of the corner of an eye.
const BLINK_INTERVAL_MS = 1000

let originalTitle = null
let intervalId = null
let showingAlert = false

function restoreTitle() {
  if (intervalId !== null) {
    clearInterval(intervalId)
    intervalId = null
  }
  if (originalTitle !== null) {
    document.title = originalTitle
    originalTitle = null
  }
  showingAlert = false
}

export function startTitleBlink(alertTitle) {
  if (typeof document === 'undefined') return
  if (document.visibilityState === 'visible' && document.hasFocus()) return

  const alreadyBlinking = intervalId !== null
  if (originalTitle === null) originalTitle = document.title

  if (!alreadyBlinking) {
    intervalId = setInterval(() => {
      showingAlert = !showingAlert
      document.title = showingAlert ? alertTitle : originalTitle
    }, BLINK_INTERVAL_MS)

    const stopOnReturn = () => {
      if (document.visibilityState === 'visible' && document.hasFocus()) {
        restoreTitle()
        document.removeEventListener('visibilitychange', stopOnReturn)
        window.removeEventListener('focus', stopOnReturn)
      }
    }
    document.addEventListener('visibilitychange', stopOnReturn)
    window.addEventListener('focus', stopOnReturn)
  }
}
