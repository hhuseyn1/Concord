import { useCallback, useMemo, useState } from 'react'

const MAX_SUGGESTIONS = 5
const MENTION_TRIGGER_REGEX = /(?:^|\s)@([a-zA-Z0-9_]{0,32})$/

export function useMentionAutocomplete({ candidates, content, setContent, textareaRef }) {
  const [trigger, setTrigger] = useState(null)
  const [activeIndex, setActiveIndex] = useState(0)

  const suggestions = useMemo(
    () =>
      trigger
        ? candidates
            .filter((candidate) => candidate.Username?.toLowerCase().startsWith(trigger.query.toLowerCase()))
            .slice(0, MAX_SUGGESTIONS)
        : [],
    [trigger, candidates],
  )

  const isOpen = Boolean(trigger) && suggestions.length > 0

  const close = useCallback(() => setTrigger(null), [])

  const handleChange = useCallback((value, selectionStart) => {
    const upToCursor = value.slice(0, selectionStart)
    const match = MENTION_TRIGGER_REGEX.exec(upToCursor)
    if (!match) {
      setTrigger(null)
      return
    }
    const query = match[1]
    setTrigger({ startIndex: selectionStart - query.length - 1, query })
    setActiveIndex(0)
  }, [])

  const handleSelect = useCallback(
    (candidate) => {
      if (!trigger || !candidate?.Username) return
      const before = content.slice(0, trigger.startIndex)
      const after = content.slice(trigger.startIndex + 1 + trigger.query.length)
      const insertion = `@${candidate.Username} `
      setContent(`${before}${insertion}${after}`)
      setTrigger(null)

      const cursorPos = before.length + insertion.length
      requestAnimationFrame(() => {
        const el = textareaRef.current
        if (!el) return
        el.focus()
        el.setSelectionRange(cursorPos, cursorPos)
      })
    },
    [trigger, content, setContent, textareaRef],
  )

  const handleKeyDown = useCallback(
    (event) => {
      if (!isOpen) return false

      if (event.key === 'ArrowDown') {
        event.preventDefault()
        setActiveIndex((index) => (index + 1) % suggestions.length)
        return true
      }
      if (event.key === 'ArrowUp') {
        event.preventDefault()
        setActiveIndex((index) => (index - 1 + suggestions.length) % suggestions.length)
        return true
      }
      if (event.key === 'Enter' || event.key === 'Tab') {
        event.preventDefault()
        handleSelect(suggestions[activeIndex])
        return true
      }
      if (event.key === 'Escape') {
        event.preventDefault()
        close()
        return true
      }
      return false
    },
    [isOpen, suggestions, activeIndex, handleSelect, close],
  )

  return { isOpen, suggestions, activeIndex, handleChange, handleKeyDown, handleSelect, close }
}
