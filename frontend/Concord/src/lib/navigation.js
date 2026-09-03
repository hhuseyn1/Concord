let navigateImpl = null

export function setNavigate(fn) {
  navigateImpl = fn
}

export function navigateTo(path, options) {
  navigateImpl?.(path, options)
}
