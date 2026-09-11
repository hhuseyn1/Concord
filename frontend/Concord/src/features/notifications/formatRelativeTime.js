const rtf = new Intl.RelativeTimeFormat(undefined, { numeric: 'auto' })

const UNITS = [
  ['year', 365 * 24 * 60 * 60],
  ['month', 30 * 24 * 60 * 60],
  ['week', 7 * 24 * 60 * 60],
  ['day', 24 * 60 * 60],
  ['hour', 60 * 60],
  ['minute', 60],
]

export function formatRelativeTime(dateString) {
  const seconds = Math.round((new Date(dateString).getTime() - Date.now()) / 1000)

  // A missing/malformed timestamp from the network shouldn't crash the whole route -
  // Intl.RelativeTimeFormat.format() throws a RangeError on a non-finite value.
  if (!Number.isFinite(seconds)) return ''

  if (Math.abs(seconds) < 30) return 'just now'

  for (const [unit, unitSeconds] of UNITS) {
    if (Math.abs(seconds) >= unitSeconds) {
      return rtf.format(Math.round(seconds / unitSeconds), unit)
    }
  }
  return rtf.format(Math.round(seconds / 60), 'minute')
}
