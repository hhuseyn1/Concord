import { useCallback, useMemo, useState } from 'react'

export function useMessageSelection(messages) {
  const [selectionMode, setSelectionMode] = useState(false)
  const [selectedIds, setSelectedIds] = useState(() => new Set())

  const enterSelectionMode = useCallback((initialMessageId) => {
    setSelectionMode(true)
    setSelectedIds(initialMessageId ? new Set([initialMessageId]) : new Set())
  }, [])

  const exitSelectionMode = useCallback(() => {
    setSelectionMode(false)
    setSelectedIds(new Set())
  }, [])

  const toggleSelect = useCallback((messageId) => {
    setSelectedIds((current) => {
      const next = new Set(current)
      if (next.has(messageId)) next.delete(messageId)
      else next.add(messageId)
      return next
    })
  }, [])

  const allSelected = messages.length > 0 && messages.every((message) => selectedIds.has(message.Id))

  const selectAll = useCallback(() => {
    setSelectedIds(new Set(messages.map((message) => message.Id)))
  }, [messages])

  const clearSelection = useCallback(() => setSelectedIds(new Set()), [])

  const toggleSelectAll = useCallback(() => {
    if (allSelected) clearSelection()
    else selectAll()
  }, [allSelected, clearSelection, selectAll])

  return useMemo(
    () => ({
      selectionMode,
      selectedIds,
      selectedCount: selectedIds.size,
      allSelected,
      enterSelectionMode,
      exitSelectionMode,
      toggleSelect,
      toggleSelectAll,
    }),
    [selectionMode, selectedIds, allSelected, enterSelectionMode, exitSelectionMode, toggleSelect, toggleSelectAll],
  )
}
