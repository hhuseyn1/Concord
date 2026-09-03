import { Hash, Volume2 } from 'lucide-react'
import { useState } from 'react'
import { Button } from '../../components/ui/Button'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { cn } from '../../lib/cn'
import { mapCreateChannelError } from './channelsErrors'
import { useCreateChannelMutation } from './channelsQueries'

const TYPES = [
  { value: 'Text', label: 'Text', icon: Hash },
  { value: 'Voice', label: 'Voice', icon: Volume2 },
]

export function CreateChannelModal({ serverId, open, onOpenChange, defaultType = 'Text' }) {
  const [name, setName] = useState('')
  const [type, setType] = useState(defaultType)
  const [nameError, setNameError] = useState('')
  const createMutation = useCreateChannelMutation(serverId)

  const [wasOpen, setWasOpen] = useState(open)
  if (open !== wasOpen) {
    setWasOpen(open)
    if (open) {
      setName('')
      setNameError('')
      setType(defaultType)
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
      const channel = await createMutation.mutateAsync({ Name: trimmed, Type: type })
      toast({ variant: 'success', title: 'Channel created', description: `"${channel.Name}" is ready.` })
      onOpenChange(false)
    } catch (error) {
      if (error?.status === 400) {
        setNameError(mapCreateChannelError(error))
      } else {
        toast({ variant: 'danger', title: 'Could not create channel', description: mapCreateChannelError(error) })
      }
    }
  }

  return (
    <Modal open={open} onOpenChange={onOpenChange} title="Create Channel" size="sm">
      <form className="flex flex-col gap-4" onSubmit={handleSubmit} noValidate>
        <div className="flex flex-col gap-1.5">
          <p className="text-sm font-medium text-fg-default">Channel type</p>
          <div className="grid grid-cols-2 gap-2">
            {TYPES.map(({ value, label, icon: Icon }) => (
              <button
                key={value}
                type="button"
                onClick={() => setType(value)}
                aria-pressed={type === value}
                className={cn(
                  'flex items-center gap-2 rounded-md border px-3 py-2 text-sm transition-colors duration-150',
                  type === value
                    ? 'border-brand bg-brand-bg text-fg-default'
                    : 'border-border-default text-fg-muted hover:bg-fg-default/5',
                )}
              >
                <Icon className="size-4 shrink-0" aria-hidden="true" />
                {label}
              </button>
            ))}
          </div>
        </div>

        <FormField label="Channel name" htmlFor="create-channel-name" error={nameError} required>
          <Input
            id="create-channel-name"
            value={name}
            onChange={(event) => setName(event.target.value)}
            placeholder={type === 'Voice' ? 'general-voice' : 'general'}
            autoFocus
          />
        </FormField>

        <Button type="submit" size="lg" disabled={createMutation.isPending}>
          {createMutation.isPending && <Spinner size="sm" />}
          {createMutation.isPending ? 'Creating…' : 'Create Channel'}
        </Button>
      </form>
    </Modal>
  )
}
