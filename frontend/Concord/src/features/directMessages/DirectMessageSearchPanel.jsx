import { useQuery } from '@tanstack/react-query'
import { Search } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import * as directMessagesService from '../../api/directMessagesService'
import { Avatar } from '../../components/ui/Avatar'
import { EmptyState } from '../../components/ui/EmptyState'
import { Input } from '../../components/ui/Input'
import { Skeleton } from '../../components/ui/Skeleton'
import { formatAbsoluteTimestamp } from '../messages/formatMessageTime'
import { jumpToMessage } from '../messages/jumpToMessage'

const MIN_QUERY_LENGTH = 2
const DEBOUNCE_MS = 350

export function DirectMessageSearchPanel({ conversationId, onNavigateToResult }) {
  const { t } = useTranslation()
  const [query, setQuery] = useState('')
  const [debouncedQuery, setDebouncedQuery] = useState('')

  useEffect(() => {
    const handle = setTimeout(() => setDebouncedQuery(query.trim()), DEBOUNCE_MS)
    return () => clearTimeout(handle)
  }, [query])

  const enabled = debouncedQuery.length >= MIN_QUERY_LENGTH

  const { data, isFetching, isError, error } = useQuery({
    queryKey: ['directMessages', conversationId, 'search', debouncedQuery],
    queryFn: () => directMessagesService.searchDirectMessages(conversationId, debouncedQuery, { pageSize: 20 }),
    enabled: enabled && Boolean(conversationId),
  })

  const results = data?.Items ?? []

  const handleResultClick = (message) => {
    jumpToMessage(message.Id)
    onNavigateToResult?.()
  }

  return (
    <div className="flex w-80 flex-col">
      <div className="border-b border-border-subtle p-3">
        <Input
          autoFocus
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder={t('messages.searchPlaceholder')}
          aria-label={t('messages.searchPlaceholder')}
        />
      </div>

      <div className="max-h-80 overflow-y-auto p-2">
        {!enabled && (
          <p className="px-2 py-3 text-center text-sm text-fg-muted">
            {t('messages.searchPlaceholder')}
          </p>
        )}

        {enabled && isFetching && (
          <div className="flex flex-col gap-2 p-2">
            {Array.from({ length: 3 }, (_, index) => (
              <Skeleton key={index} className="h-10 w-full" />
            ))}
          </div>
        )}

        {enabled && !isFetching && isError && (
          <p className="px-2 py-3 text-center text-sm text-danger">{error?.message || 'Search failed.'}</p>
        )}

        {enabled && !isFetching && !isError && results.length === 0 && (
          <EmptyState icon={Search} title={t('messages.searchNoResults')} compact />
        )}

        {enabled && !isFetching && !isError && results.length > 0 && (
          <div className="flex flex-col gap-0.5">
            {results.map((message) => {
              const senderName =
                message.Sender?.Username ||
                [message.Sender?.Name, message.Sender?.Surname].filter(Boolean).join(' ') ||
                'Unknown user'
              return (
                <button
                  key={message.Id}
                  type="button"
                  onClick={() => handleResultClick(message)}
                  className="flex items-start gap-2 rounded-md px-2 py-1.5 text-left transition-colors duration-150 hover:bg-fg-default/5"
                  title={t('messages.jumpToMessage')}
                >
                  <Avatar src={message.Sender?.AvatarUrl ?? undefined} name={senderName} size="sm" />
                  <div className="min-w-0 flex-1">
                    <p className="flex items-baseline gap-1.5 text-xs">
                      <span className="font-medium text-fg-default">{senderName}</span>
                      <span className="text-fg-muted">{formatAbsoluteTimestamp(message.Created)}</span>
                    </p>
                    <p className="truncate text-sm text-fg-muted">{message.Content}</p>
                  </div>
                </button>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}
