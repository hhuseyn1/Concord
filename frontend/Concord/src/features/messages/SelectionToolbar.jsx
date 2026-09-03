import { useState } from 'react'
import { Button } from '../../components/ui/Button'
import { Modal } from '../../components/ui/Modal'
import { Spinner } from '../../components/ui/Spinner'

export function SelectionToolbar({ selectedCount, allSelected, onToggleSelectAll, onRemoveSelected, onCancel }) {
  const [confirmOpen, setConfirmOpen] = useState(false)
  const [isRemoving, setIsRemoving] = useState(false)

  const handleConfirm = async () => {
    setIsRemoving(true)
    try {
      await onRemoveSelected()
      setConfirmOpen(false)
      onCancel()
    } finally {
      setIsRemoving(false)
    }
  }

  return (
    <>
      <div className="flex shrink-0 flex-wrap items-center gap-3 border-b border-border-subtle bg-surface-sidebar px-4 py-2">
        <span className="text-sm font-medium text-fg-default">
          {selectedCount} selected
        </span>
        <Button variant="ghost" size="sm" onClick={onToggleSelectAll}>
          {allSelected ? 'Deselect all' : 'Select all'}
        </Button>
        <div className="ml-auto flex items-center gap-2">
          <Button variant="danger" size="sm" disabled={selectedCount === 0} onClick={() => setConfirmOpen(true)}>
            Remove Selected
          </Button>
          <Button variant="ghost" size="sm" onClick={onCancel}>
            Cancel
          </Button>
        </div>
      </div>

      <Modal
        open={confirmOpen}
        onOpenChange={setConfirmOpen}
        title={`Remove ${selectedCount} message${selectedCount === 1 ? '' : 's'}?`}
        description="Your own selected messages are deleted for everyone; anyone else's selected messages are hidden from your view only. This can't be undone."
        footer={
          <>
            <Button variant="ghost" disabled={isRemoving} onClick={() => setConfirmOpen(false)}>
              Cancel
            </Button>
            <Button variant="danger" disabled={isRemoving} onClick={handleConfirm}>
              {isRemoving && <Spinner size="sm" />}
              Remove
            </Button>
          </>
        }
      />
    </>
  )
}
