import { useNavigate } from 'react-router-dom'
import { Button } from '../../components/ui/Button'
import { Modal } from '../../components/ui/Modal'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { mapLeaveServerError } from './serversErrors'
import { useLeaveServerMutation } from './serversQueries'

export function LeaveServerModal({ server, open, onOpenChange }) {
  const navigate = useNavigate()
  const leaveMutation = useLeaveServerMutation()

  const handleLeave = async () => {
    try {
      await leaveMutation.mutateAsync(server.Id)
      toast({ description: `You left ${server?.Name || 'the server'}.` })
      onOpenChange(false)
      navigate('/')
    } catch (error) {
      toast({ variant: 'danger', title: 'Could not leave server', description: mapLeaveServerError(error) })
    }
  }

  return (
    <Modal
      open={open}
      onOpenChange={onOpenChange}
      title={`Leave ${server?.Name || 'this server'}?`}
      description="You'll need a new invite to rejoin later."
      footer={
        <>
          <Button variant="ghost" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button variant="danger" disabled={leaveMutation.isPending} onClick={handleLeave}>
            {leaveMutation.isPending && <Spinner size="sm" />}
            Leave Server
          </Button>
        </>
      }
    >
      <p className="text-sm text-fg-muted">This removes you from the server immediately.</p>
    </Modal>
  )
}
