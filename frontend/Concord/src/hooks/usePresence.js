import { useContext } from 'react'
import { PresenceContext } from '../app/PresenceContext'

export function usePresence() {
  const context = useContext(PresenceContext)
  if (context === undefined) {
    throw new Error('usePresence must be used within a PresenceProvider')
  }
  return context
}
