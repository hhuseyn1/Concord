const reconnectingIds = new Set()
let listeners = []

function notify() {
  const isReconnecting = reconnectingIds.size > 0
  for (const listener of listeners) listener(isReconnecting)
}

export function reportReconnecting(id) {
  reconnectingIds.add(id)
  notify()
}

export function reportReconnected(id) {
  reconnectingIds.delete(id)
  notify()
}

export function reportSettled(id) {
  reconnectingIds.delete(id)
  notify()
}

export function subscribeConnectionStatus(listener) {
  listeners.push(listener)
  return () => {
    listeners = listeners.filter((item) => item !== listener)
  }
}

export function isAnyHubReconnecting() {
  return reconnectingIds.size > 0
}
