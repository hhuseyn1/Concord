import { useContext } from 'react'
import { VoiceCallContext } from '../app/VoiceCallContext'

export function useVoiceCall() {
  const context = useContext(VoiceCallContext)
  if (context === undefined) {
    throw new Error('useVoiceCall must be used within a VoiceCallProvider')
  }
  return context
}
