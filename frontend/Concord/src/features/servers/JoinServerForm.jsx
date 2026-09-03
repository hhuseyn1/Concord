import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { Button } from '../../components/ui/Button'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { mapJoinServerError } from './serversErrors'
import { useJoinServerMutation } from './serversQueries'

export function JoinServerForm({ onDone }) {
  const [searchParams] = useSearchParams()
  const [code, setCode] = useState(() => searchParams.get('invite') ?? '')
  const [codeError, setCodeError] = useState('')
  const joinMutation = useJoinServerMutation()

  const handleSubmit = async (event) => {
    event.preventDefault()
    const trimmed = code.trim()
    if (!trimmed) {
      setCodeError('Enter an invite code.')
      return
    }
    setCodeError('')
    try {
      const server = await joinMutation.mutateAsync(trimmed)
      toast({ variant: 'success', title: 'Joined server', description: `You're in "${server.Name}".` })
      onDone?.()
    } catch (error) {
      if (error?.status === 404) {
        setCodeError(mapJoinServerError(error))
      } else {
        toast({ variant: 'danger', title: 'Could not join server', description: mapJoinServerError(error) })
      }
    }
  }

  return (
    <form className="flex flex-col gap-4 pt-1" onSubmit={handleSubmit} noValidate>
      <FormField
        label="Invite code"
        htmlFor="join-server-code"
        error={codeError}
        hint={!codeError ? 'Ask a server owner for an invite code.' : undefined}
        required
      >
        <Input
          id="join-server-code"
          value={code}
          onChange={(event) => setCode(event.target.value)}
          placeholder="e.g. aB3xQ9"
          autoFocus
        />
      </FormField>

      <Button type="submit" size="lg" disabled={joinMutation.isPending}>
        {joinMutation.isPending && <Spinner size="sm" />}
        {joinMutation.isPending ? 'Joining…' : 'Join Server'}
      </Button>
    </form>
  )
}
