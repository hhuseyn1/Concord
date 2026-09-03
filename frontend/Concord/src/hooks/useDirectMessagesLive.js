import { useContext } from 'react'
import { DirectMessagesContext } from '../app/DirectMessagesContext'

export function useDirectMessagesLive() {
  const context = useContext(DirectMessagesContext)
  if (context === undefined) {
    throw new Error('useDirectMessagesLive must be used within a DirectMessagesProvider')
  }
  return context
}
