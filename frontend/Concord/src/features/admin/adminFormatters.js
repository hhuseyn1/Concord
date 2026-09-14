// Used by AuditLogSection.jsx to render human-readable action labels for audit log entries.
export function formatAction(action) {
  if (!action) return action
  return action.replace(/([a-z0-9])([A-Z])/g, '$1 $2').replace(/([A-Z]+)([A-Z][a-z])/g, '$1 $2')
}
