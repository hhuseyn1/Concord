import { Hash, MessageCircle, Search } from 'lucide-react'
import { useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Avatar } from '../../components/ui/Avatar'
import { EmptyState } from '../../components/ui/EmptyState'
import { Input } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { flattenConversationPages, useConversations } from '../directMessages/directMessagesQueries'
import { useChannels } from '../channels/channelsQueries'

export function ForwardMessageModal({ open, onOpenChange, sourceServerId, sourceChannelId, sourceConversationId, onPick }) {
  const { t } = useTranslation()
  const [query, setQuery] = useState('')

  const { data: channels } = useChannels(sourceServerId, { enabled: open && Boolean(sourceServerId) })
  const { data: conversationPages } = useConversations()

  const textChannels = useMemo(
    () => (channels ?? []).filter((channel) => channel.Type === 'Text' && channel.Id !== sourceChannelId),
    [channels, sourceChannelId],
  )

  const conversations = useMemo(
    () => flattenConversationPages(conversationPages?.pages).filter((c) => c.Id !== sourceConversationId),
    [conversationPages, sourceConversationId],
  )

  const needle = query.trim().toLowerCase()
  const filteredChannels = needle ? textChannels.filter((c) => c.Name?.toLowerCase().includes(needle)) : textChannels
  const filteredConversations = needle
    ? conversations.filter((c) => {
        const name = c.OtherUser?.Username || [c.OtherUser?.Name, c.OtherUser?.Surname].filter(Boolean).join(' ')
        return (name || '').toLowerCase().includes(needle)
      })
    : conversations

  const handleClose = (next) => {
    onOpenChange(next)
    if (!next) setQuery('')
  }

  const isEmpty = filteredChannels.length === 0 && filteredConversations.length === 0

  return (
    <Modal open={open} onOpenChange={handleClose} title={t('messages.forwardMessage')} description={t('messages.forwardDescription')}>
      <div className="flex flex-col gap-3">
        <div className="relative">
          <Search className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-fg-muted" aria-hidden="true" />
          <Input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder={t('messages.forwardSearchPlaceholder')}
            className="pl-9"
            autoFocus
          />
        </div>

        {isEmpty ? (
          <EmptyState title={t('messages.forwardNoDestinations')} compact />
        ) : (
          <div className="flex max-h-72 flex-col gap-0.5 overflow-y-auto">
            {filteredChannels.length > 0 && (
              <p className="px-2 pt-1 pb-0.5 text-xs font-semibold tracking-wide text-fg-muted uppercase">{t('messages.forwardChannels')}</p>
            )}
            {filteredChannels.map((channel) => (
              <button
                key={channel.Id}
                type="button"
                onClick={() => onPick({ targetChannelId: channel.Id })}
                className="flex items-center gap-2 rounded-md px-2 py-1.5 text-left transition-colors duration-150 hover:bg-fg-default/5"
              >
                <Hash className="size-4 shrink-0 text-fg-muted" aria-hidden="true" />
                <span className="truncate text-sm text-fg-default">{channel.Name}</span>
              </button>
            ))}

            {filteredConversations.length > 0 && (
              <p className="px-2 pt-2 pb-0.5 text-xs font-semibold tracking-wide text-fg-muted uppercase">{t('messages.forwardDirectMessages')}</p>
            )}
            {filteredConversations.map((conversation) => {
              const displayName =
                conversation.OtherUser?.Username ||
                [conversation.OtherUser?.Name, conversation.OtherUser?.Surname].filter(Boolean).join(' ') ||
                t('common.unknownUser')
              return (
                <button
                  key={conversation.Id}
                  type="button"
                  onClick={() => onPick({ targetConversationId: conversation.Id })}
                  className="flex items-center gap-2 rounded-md px-2 py-1.5 text-left transition-colors duration-150 hover:bg-fg-default/5"
                >
                  <Avatar src={conversation.OtherUser?.AvatarUrl ?? undefined} name={displayName} size="sm" />
                  <span className="truncate text-sm text-fg-default">{displayName}</span>
                  <MessageCircle className="ml-auto size-3.5 shrink-0 text-fg-muted" aria-hidden="true" />
                </button>
              )
            })}
          </div>
        )}
      </div>
    </Modal>
  )
}
