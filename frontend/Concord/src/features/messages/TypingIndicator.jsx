import { useQuery } from '@tanstack/react-query'
import * as usersService from '../../api/usersService'

function useTypingDisplayName(userId) {
  const { data: profile } = useQuery({
    queryKey: ['users', userId],
    queryFn: () => usersService.getUserById(userId),
    enabled: Boolean(userId),
    staleTime: 5 * 60 * 1000,
  })
  return profile?.Username || [profile?.Name, profile?.Surname].filter(Boolean).join(' ') || 'Someone'
}

export function TypingIndicator({ typingUserIds }) {
  const ids = Array.from(typingUserIds ?? [])
  const firstName = useTypingDisplayName(ids[0])
  const secondName = useTypingDisplayName(ids[1])

  if (ids.length === 0) return null

  const text =
    ids.length === 1
      ? `${firstName} is typing…`
      : ids.length === 2
        ? `${firstName} and ${secondName} are typing…`
        : `${firstName}, ${secondName}, and others are typing…`

  return (
    <div className="flex h-6 shrink-0 items-center gap-1.5 px-4 text-xs text-fg-muted">
      <span className="flex gap-0.5" aria-hidden="true">
        <span className="size-1 animate-bounce rounded-full bg-fg-muted [animation-delay:-0.3s]" />
        <span className="size-1 animate-bounce rounded-full bg-fg-muted [animation-delay:-0.15s]" />
        <span className="size-1 animate-bounce rounded-full bg-fg-muted" />
      </span>
      <span>{text}</span>
    </div>
  )
}
