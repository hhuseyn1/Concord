export function jumpToMessage(messageId) {
  const el = document.querySelector(`[data-message-id="${messageId}"]`)
  if (!el) return false
  el.scrollIntoView({ behavior: 'smooth', block: 'center' })
  el.classList.add('bg-brand-bg/60')
  setTimeout(() => el.classList.remove('bg-brand-bg/60'), 1200)
  return true
}
