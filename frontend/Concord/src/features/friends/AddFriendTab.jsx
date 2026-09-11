import { Check, Search, UserPlus, X } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useTranslation } from 'react-i18next'
import * as usersService from '../../api/usersService'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { Input } from '../../components/ui/Input'
import { Skeleton } from '../../components/ui/Skeleton'
import { Spinner } from '../../components/ui/Spinner'
import { FriendRow } from './FriendRow'
import { useRelationshipActions } from './useRelationshipActions'

const MIN_QUERY_LENGTH = 2
const DEBOUNCE_MS = 350

export function AddFriendTab() {
  const { t } = useTranslation()
  const [query, setQuery] = useState('')
  const [debouncedQuery, setDebouncedQuery] = useState('')

  useEffect(() => {
    const handle = setTimeout(() => setDebouncedQuery(query.trim()), DEBOUNCE_MS)
    return () => clearTimeout(handle)
  }, [query])

  const trimmed = debouncedQuery
  const enabled = trimmed.length >= MIN_QUERY_LENGTH

  const { data, isFetching, isError, error, refetch } = useQuery({
    queryKey: ['friends', 'search', trimmed],
    queryFn: () => usersService.searchUsers(trimmed),
    enabled,
  })

  const { isPending, sendRequest, acceptRequest, declineRequest } = useRelationshipActions({
    onChanged: refetch,
  })

  const renderActions = (user) => {
    const pending = isPending(user.Id)

    if (user.RelationshipStatus === 'Friends') {
      return <Badge variant="neutral">{t('friends.alreadyFriends')}</Badge>
    }

    if (user.RelationshipStatus === 'OutgoingRequest') {
      return (
        <Button size="sm" variant="secondary" disabled>
          {t('friends.requestSent')}
        </Button>
      )
    }

    if (user.RelationshipStatus === 'IncomingRequest') {
      return (
        <>
          <Button size="sm" disabled={pending} onClick={() => acceptRequest(user)}>
            {pending ? <Spinner size="sm" /> : <Check className="size-4" aria-hidden="true" />}
            {t('friends.accept')}
          </Button>
          <Button size="sm" variant="secondary" disabled={pending} onClick={() => declineRequest(user)}>
            <X className="size-4" aria-hidden="true" />
            {t('friends.decline')}
          </Button>
        </>
      )
    }

    return (
      <Button size="sm" disabled={pending} onClick={() => sendRequest(user)}>
        {pending ? (
          <Spinner size="sm" />
        ) : (
          <>
            <UserPlus className="size-4" aria-hidden="true" />
            {t('friends.add')}
          </>
        )}
      </Button>
    )
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="relative">
        <Search
          className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-fg-muted"
          aria-hidden="true"
        />
        <Input
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="Enter their exact username…"
          className="pl-9"
          aria-label="Search for a user by their exact username"
        />
      </div>

      {trimmed.length > 0 && !enabled && (
        <p className="text-sm text-fg-muted">Keep typing - at least {MIN_QUERY_LENGTH} characters.</p>
      )}

      {trimmed.length === 0 && (
        <EmptyState
          icon={UserPlus}
          title="Find friends by username"
          description="You'll need their exact username - this isn't a browsable directory. You, existing friends, and blocked users won't show up here."
        />
      )}

      {enabled && isFetching && (
        <div className="flex flex-col gap-1">
          {Array.from({ length: 3 }, (_, index) => (
            <div key={index} className="flex items-center gap-3 px-3 py-2">
              <Skeleton className="size-10 rounded-full" />
              <Skeleton className="h-4 w-32" />
            </div>
          ))}
        </div>
      )}

      {enabled && !isFetching && isError && (
        <EmptyState title="Search failed" description={error?.message || 'Something went wrong.'} />
      )}

      {enabled && !isFetching && !isError && data?.length === 0 && (
        <EmptyState icon={Search} title="No users found" description={`Nobody matches "${trimmed}".`} />
      )}

      {enabled && !isFetching && !isError && data?.length > 0 && (
        <div className="flex flex-col gap-0.5">
          {data.map((user) => (
            <FriendRow key={user.Id} user={user} actions={renderActions(user)} />
          ))}
        </div>
      )}
    </div>
  )
}
