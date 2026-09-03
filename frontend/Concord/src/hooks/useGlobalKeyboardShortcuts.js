import { useEffect, useState } from 'react'
import { useVoiceCall } from './useVoiceCall'

export function useGlobalKeyboardShortcuts() {
  const [isSearchOpen, setSearchOpen] = useState(false)
  const { activeCall, toggleMute, toggleDeafen } = useVoiceCall()

  useEffect(() => {
    const handleKeyDown = (event) => {
      const isModifier = event.ctrlKey || event.metaKey

      if (isModifier && event.key.toLowerCase() === 'k') {
        event.preventDefault()
        setSearchOpen((open) => !open)
        return
      }

      if (isModifier && event.shiftKey && activeCall && event.key.toLowerCase() === 'm') {
        event.preventDefault()
        toggleMute()
        return
      }

      if (isModifier && event.shiftKey && activeCall && event.key.toLowerCase() === 'd') {
        event.preventDefault()
        toggleDeafen()
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [activeCall, toggleMute, toggleDeafen])

  return { isSearchOpen, setSearchOpen }
}
