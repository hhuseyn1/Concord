
export function toDateInputValue(date) {
  return date.toISOString().slice(0, 10)
}

function startOfUtcMonth(date) {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1))
}

export function thisMonthRange() {
  const now = new Date()
  return { from: toDateInputValue(startOfUtcMonth(now)), to: toDateInputValue(now) }
}

export function lastMonthRange() {
  const now = new Date()
  const firstOfThisMonth = startOfUtcMonth(now)
  const lastDayOfPreviousMonth = new Date(firstOfThisMonth.getTime() - 1)
  return { from: toDateInputValue(startOfUtcMonth(lastDayOfPreviousMonth)), to: toDateInputValue(lastDayOfPreviousMonth) }
}

export function lastNMonthsRange(months) {
  const now = new Date()
  const from = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - (months - 1), 1))
  return { from: toDateInputValue(from), to: toDateInputValue(now) }
}
