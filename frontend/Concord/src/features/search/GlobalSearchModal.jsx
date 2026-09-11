import { useQuery } from '@tanstack/react-query'
import { Hash, MessageCircle, Search } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useNavigate } from 'react-router-dom'
import * as globalSearchService from '../../api/globalSearchService'
import { Avatar } from '../../components/ui/Avatar'
import { EmptyState } from '../../components/ui/EmptyState'
import { Input } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { Skeleton } from '../../components/ui/Skeleton'
import { formatAbsoluteTimestamp } from '../messages/formatMessageTime'
import { jumpToMessage } from '../messages/jumpToMessage'

const MIN_QUERY_LENGTH = 2
const DEBOUNCE_MS = 350
const JUMP_AFTER_NAVIGATE_DELAY_MS = 400

export function GlobalSearchModal({ open, onOpenChange }) {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const [query, setQuery] = useState('')
  const [debouncedQuery, setDebouncedQuery] = useState('')

  useEffect(() => {
    const handle = setTimeout(() => setDebouncedQuery(query.trim()), DEBOUNCE_MS)
    return () => clearTimeout(handle)
  }, [query])

  const [prevOpen, setPrevOpen] = useState(open)
  if (open !== prevOpen) {
    setPrevOpen(open)
    if (!open) {
      setQuery('')
      setDebouncedQuery('')
    }
  }

  const enabled = open && debouncedQuery.length >= MIN_QUERY_LENGTH

  const { data, isFetching, isError, error } = useQuery({
    queryKey: ['search', 'messages', debouncedQuery],
    queryFn: () => globalSearchService.searchMessages(debouncedQuery, { pageSize: 20 }),
    enabled,
  })

  const results = data?.Items ?? []

  const handleResultClick = (result) => {
    const path = result.SourceType === 'Channel' ? `/cabinet/servers/${result.ServerId}/channels/${result.ChannelId}` : `/cabinet/dm/${result.ConversationId}`
    navigate(path)
    onOpenChange(false)
    setTimeout(() => jumpToMessage(result.MessageId), JUMP_AFTER_NAVIGATE_DELAY_MS)
  }

  return (
    <Modal open={open} onOpenChange={onOpenChange} title={t('search.title')} description={t('search.description')}>
      <div className="flex flex-col gap-3">
        <div className="relative">
          <Search className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-fg-muted" aria-hidden="true" />
          <Input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder={t('search.placeholder')}
            className="pl-9"
            autoFocus
            aria-label={t('search.placeholder')}
          />
        </div>

        <div className="max-h-96 overflow-y-auto">
          {!enabled && query.trim().length > 0 && query.trim().length < MIN_QUERY_LENGTH && (
            <p className="px-2 py-3 text-center text-sm text-fg-muted">{t('search.typeMore')}</p>
          )}

          {enabled && isFetching && (
            <div className="flex flex-col gap-2 p-2">
              {Array.from({ length: 4 }, (_, index) => (
                <Skeleton key={index} className="h-10 w-full" />
              ))}
            </div>
          )}

          {enabled && !isFetching && isError && (
            <p className="px-2 py-3 text-center text-sm text-danger">{error?.message || t('search.failed')}</p>
          )}

          {enabled && !isFetching && !isError && results.length === 0 && (
            <EmptyState icon={Search} title={t('search.noResults')} compact />
          )}

          {enabled && !isFetching && !isError && results.length > 0 && (
            <div className="flex flex-col gap-0.5">
              {results.map((result) => {
                const senderName =
                  result.Sender?.Username ||
                  [result.Sender?.Name, result.Sender?.Surname].filter(Boolean).join(' ') ||
                  t('common.unknownUser')
                return (
                  <button
                    key={result.MessageId}
                    type="button"
                    onClick={() => handleResultClick(result)}
                    className="flex items-start gap-2 rounded-md px-2 py-1.5 text-left transition-colors duration-150 hover:bg-fg-default/5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand"
                  >
                    <Avatar src={result.Sender?.AvatarUrl ?? undefined} name={senderName} size="sm" />
                    <div className="min-w-0 flex-1">
                      <p className="flex items-baseline gap-1.5 text-xs">
                        <span className="font-medium text-fg-default">{senderName}</span>
                        <span className="flex items-center gap-0.5 text-fg-muted">
                          {result.SourceType === 'Channel' ? (
                            <Hash className="size-3" aria-hidden="true" />
                          ) : (
                            <MessageCircle className="size-3" aria-hidden="true" />
                          )}
                        </span>
                        <span className="text-fg-muted">{formatAbsoluteTimestamp(result.Created)}</span>
                      </p>
                      <p className="truncate text-sm text-fg-muted">{result.Content}</p>
                    </div>
                  </button>
                )
              })}
            </div>
          )}
        </div>
      </div>
    </Modal>
  )
}
