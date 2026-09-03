import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Button } from '../../components/ui/Button'
import { Input } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { mapDeleteServerError } from './serversErrors'
import { useDeleteServerMutation } from './serversQueries'

export function DeleteServerModal({ server, open, onOpenChange }) {
  const navigate = useNavigate()
  const deleteMutation = useDeleteServerMutation()
  const [confirmText, setConfirmText] = useState('')

  const serverName = server?.Name || 'this server'
  const canDelete = confirmText === serverName && !deleteMutation.isPending

  const handleClose = (nextOpen) => {
    if (!nextOpen) setConfirmText('')
    onOpenChange(nextOpen)
  }

  const handleDelete = async () => {
    if (!canDelete) return
    try {
      await deleteMutation.mutateAsync(server.Id)
      toast({ description: `${serverName} was deleted.` })
      handleClose(false)
      navigate('/')
    } catch (error) {
      toast({ variant: 'danger', title: 'Could not delete server', description: mapDeleteServerError(error) })
    }
  }

  return (
    <Modal
      open={open}
      onOpenChange={handleClose}
      title={`Delete ${serverName}?`}
      description="This permanently deletes every channel, message, and invite in this server for everyone. This can't be undone."
      footer={
        <>
          <Button variant="ghost" onClick={() => handleClose(false)}>
            Cancel
          </Button>
          <Button variant="danger" disabled={!canDelete} onClick={handleDelete}>
            {deleteMutation.isPending && <Spinner size="sm" />}
            Delete Server
          </Button>
        </>
      }
    >
      <label className="flex flex-col gap-1.5 text-sm text-fg-muted" htmlFor="delete-server-confirm">
        Type <span className="font-semibold text-fg-default">{serverName}</span> to confirm.
        <Input
          id="delete-server-confirm"
          value={confirmText}
          onChange={(event) => setConfirmText(event.target.value)}
          autoFocus
          autoComplete="off"
        />
      </label>
    </Modal>
  )
}
