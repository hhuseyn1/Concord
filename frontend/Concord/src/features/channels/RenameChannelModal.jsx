import { useState } from 'react'
import { Button } from '../../components/ui/Button'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { mapRenameChannelError } from './channelsErrors'
import { useUpdateChannelMutation } from './channelsQueries'

export function RenameChannelModal({ channel, serverId, open, onOpenChange }) {
  const [name, setName] = useState(channel?.Name || '')
  const [nameError, setNameError] = useState('')
  const updateMutation = useUpdateChannelMutation(serverId)

  const [wasOpen, setWasOpen] = useState(open)
  if (open !== wasOpen) {
    setWasOpen(open)
    if (open) {
      setName(channel?.Name || '')
      setNameError('')
    }
  }

  const handleSubmit = async (event) => {
    event.preventDefault()
    const trimmed = name.trim()
    if (!trimmed) {
      setNameError('Channel name is required.')
      return
    }
    setNameError('')
    try {
      await updateMutation.mutateAsync({ channelId: channel.Id, name: trimmed })
      toast({ variant: 'success', description: `Channel renamed to "${trimmed}".` })
      onOpenChange(false)
    } catch (error) {
      if (error?.status === 400) {
        setNameError(mapRenameChannelError(error))
      } else {
        toast({ variant: 'danger', title: 'Could not rename channel', description: mapRenameChannelError(error) })
        onOpenChange(false)
      }
    }
  }

  return (
    <Modal open={open} onOpenChange={onOpenChange} title={`Rename #${channel?.Name || 'channel'}`} size="sm">
      <form className="flex flex-col gap-4" onSubmit={handleSubmit} noValidate>
        <FormField label="Channel name" htmlFor="rename-channel-name" error={nameError} required>
          <Input
            id="rename-channel-name"
            value={name}
            onChange={(event) => setName(event.target.value)}
            autoFocus
          />
        </FormField>

        <div className="flex justify-end gap-2">
          <Button type="button" variant="ghost" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button type="submit" disabled={updateMutation.isPending}>
            {updateMutation.isPending && <Spinner size="sm" />}
            Save
          </Button>
        </div>
      </form>
    </Modal>
  )
}
