import { useQueries } from '@tanstack/react-query'
import { useMemo } from 'react'
import * as usersService from '../../api/usersService'

export function useMentionedUsers(mentionedUserIds) {
  const ids = mentionedUserIds ?? []

  const results = useQueries({
    queries: ids.map((id) => ({
      queryKey: ['users', id],
      queryFn: () => usersService.getUserById(id),
      enabled: Boolean(id),
      staleTime: 5 * 60 * 1000,
    })),
  })

  return useMemo(() => {
    const byUsername = new Map()
    for (const result of results) {
      if (result.data?.Username) byUsername.set(result.data.Username.toLowerCase(), result.data)
    }
    return byUsername
  }, [results])
}
