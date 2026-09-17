import { useEffect, useRef } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { toast } from '../../components/ui/Toast'
import { clearPendingInvite, getPendingInvite } from './pendingInvite'
import { mapJoinServerError } from './serversErrors'
import { useJoinServerMutation } from './serversQueries'

export function PendingInviteHandler() {
  const [searchParams, setSearchParams] = useSearchParams()
  const navigate = useNavigate()
  const joinMutation = useJoinServerMutation()
  const attemptedCodeRef = useRef(null)

  useEffect(() => {
    const code = searchParams.get('invite') ?? getPendingInvite()
    if (!code || attemptedCodeRef.current === code || joinMutation.isPending) return
    attemptedCodeRef.current = code

    const stripInviteParam = () => {
      setSearchParams(
        (params) => {
          params.delete('invite')
          return params
        },
        { replace: true },
      )
    }

    ;(async () => {
      try {
        const server = await joinMutation.mutateAsync(code)
        clearPendingInvite()
        stripInviteParam()
        toast(
          server.JoinedNow
            ? { variant: 'success', title: 'Joined server', description: `You're in "${server.Name}".` }
            : { variant: 'info', title: 'Already a member', description: `You're already in "${server.Name}".` },
        )
        navigate(`/cabinet/servers/${server.Id}`, { replace: true })
      } catch (error) {
        clearPendingInvite()
        stripInviteParam()
        toast({ variant: 'danger', title: 'Could not join server', description: mapJoinServerError(error) })
      }
    })()
  }, [searchParams])

  return null
}
