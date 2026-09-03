const DAY_MS = 24 * 60 * 60 * 1000

function isSameDay(a, b) {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
}

const timeFormatter = new Intl.DateTimeFormat(undefined, { hour: 'numeric', minute: '2-digit' })
const dateTimeFormatter = new Intl.DateTimeFormat(undefined, {
  year: 'numeric',
  month: 'short',
  day: 'numeric',
  hour: 'numeric',
  minute: '2-digit',
})

export function formatShortTime(dateString) {
  return timeFormatter.format(new Date(dateString))
}

export function formatGroupTimestamp(dateString) {
  const date = new Date(dateString)
  const now = new Date()
  if (isSameDay(date, now)) return `Today at ${timeFormatter.format(date)}`
  if (isSameDay(date, new Date(now.getTime() - DAY_MS))) return `Yesterday at ${timeFormatter.format(date)}`
  return dateTimeFormatter.format(date)
}

export function formatAbsoluteTimestamp(dateString) {
  return dateTimeFormatter.format(new Date(dateString))
}
