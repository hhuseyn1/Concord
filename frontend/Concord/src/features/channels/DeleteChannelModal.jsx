import { useNavigate, useParams } from 'react-router-dom'
import { Button } from '../../components/ui/Button'
import { Modal } from '../../components/ui/Modal'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { mapDeleteChannelError } from './channelsErrors'
import { useDeleteChannelMutation } from './channelsQueries'

export function DeleteChannelModal({ channel, serverId, open, onOpenChange }) {
  const { channelId: activeChannelId } = useParams()
  const navigate = useNavigate()
  const deleteMutation = useDeleteChannelMutation(serverId)

  const handleDelete = async () => {
    try {
      await deleteMutation.mutateAsync(channel.Id)
      toast({ description: `#${channel.Name} was deleted.` })
      onOpenChange(false)
      if (channel.Id === activeChannelId) {
        navigate(`/servers/${serverId}`)
      }
    } catch (error) {
      toast({ variant: 'danger', title: 'Could not delete channel', description: mapDeleteChannelError(error) })
    }
  }

  return (
    <Modal
      open={open}
      onOpenChange={onOpenChange}
      title={`Delete #${channel?.Name || 'channel'}?`}
      description="This can't be undone. All messages in this channel will be lost."
      footer={
        <>
          <Button variant="ghost" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button variant="danger" disabled={deleteMutation.isPending} onClick={handleDelete}>
            {deleteMutation.isPending && <Spinner size="sm" />}
            Delete Channel
          </Button>
        </>
      }
    >
      <p className="text-sm text-fg-muted">This removes the channel for everyone in the server immediately.</p>
    </Modal>
  )
}
