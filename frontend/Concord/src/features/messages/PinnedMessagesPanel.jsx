import { Pin, PinOff } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Avatar } from '../../components/ui/Avatar'
import { EmptyState } from '../../components/ui/EmptyState'
import { IconButton } from '../../components/ui/IconButton'
import { Skeleton } from '../../components/ui/Skeleton'
import { toast } from '../../components/ui/Toast'
import { Tooltip } from '../../components/ui/Tooltip'
import { usePinnedDirectMessages, useUnpinDirectMessageMutation } from '../directMessages/directMessagesQueries'
import { mapPinDirectMessageError } from '../directMessages/directMessagesErrors'
import { formatAbsoluteTimestamp } from './formatMessageTime'
import { jumpToMessage } from './jumpToMessage'
import { mapPinMessageError } from './messagesErrors'
import { usePinnedMessages, useUnpinMessageMutation } from './messagesQueries'

export function PinnedMessagesPanel({ serverId, channelId, conversationId, onNavigateToResult }) {
  const { t } = useTranslation()
  const isChannel = Boolean(serverId && channelId)

  const channelQuery = usePinnedMessages(serverId, channelId, { enabled: isChannel })
  const dmQuery = usePinnedDirectMessages(conversationId, { enabled: !isChannel })
  const { data, isLoading, isError } = isChannel ? channelQuery : dmQuery

  const channelUnpinMutation = useUnpinMessageMutation(serverId, channelId)
  const dmUnpinMutation = useUnpinDirectMessageMutation(conversationId)

  const handleUnpin = async (messageId) => {
    try {
      if (isChannel) {
        await channelUnpinMutation.mutateAsync(messageId)
      } else {
        await dmUnpinMutation.mutateAsync(messageId)
      }
    } catch (error) {
      toast({
        variant: 'danger',
        title: 'Could not unpin message',
        description: isChannel ? mapPinMessageError(error) : mapPinDirectMessageError(error),
      })
    }
  }

  const messages = data ?? []

  return (
    <div className="flex w-80 max-w-[calc(100vw-2rem)] flex-col">
      <div className="border-b border-border-subtle px-3 py-2">
        <p className="text-sm font-semibold text-fg-heading">{t('messages.pinnedMessages')}</p>
      </div>

      <div className="max-h-80 overflow-y-auto p-2">
        {isLoading && (
          <div className="flex flex-col gap-2 p-2">
            {Array.from({ length: 3 }, (_, index) => (
              <Skeleton key={index} className="h-10 w-full" />
            ))}
          </div>
        )}

        {!isLoading && isError && (
          <p className="px-2 py-3 text-center text-sm text-danger">{t('messages.pinnedLoadError')}</p>
        )}

        {!isLoading && !isError && messages.length === 0 && (
          <EmptyState icon={Pin} title={t('messages.noPinnedMessages')} compact />
        )}

        {!isLoading && !isError && messages.length > 0 && (
          <div className="flex flex-col gap-0.5">
            {messages.map((message) => {
              const senderName =
                message.Sender?.Username ||
                [message.Sender?.Name, message.Sender?.Surname].filter(Boolean).join(' ') ||
                t('common.unknownUser')
              return (
                <div key={message.Id} className="group flex items-start gap-2 rounded-md px-2 py-1.5 hover:bg-fg-default/5">
                  <button
                    type="button"
                    onClick={() => {
                      jumpToMessage(message.Id)
                      onNavigateToResult?.()
                    }}
                    className="flex min-w-0 flex-1 items-start gap-2 text-left"
                  >
                    <Avatar src={message.Sender?.AvatarUrl ?? undefined} name={senderName} size="sm" />
                    <div className="min-w-0 flex-1">
                      <p className="flex items-baseline gap-1.5 text-xs">
                        <span className="font-medium text-fg-default">{senderName}</span>
                        <span className="text-fg-muted">{formatAbsoluteTimestamp(message.Created)}</span>
                      </p>
                      <p className="truncate text-sm text-fg-muted">{message.Content || t('messages.attachment')}</p>
                    </div>
                  </button>
                  <Tooltip content={t('messages.unpin')}>
                    <IconButton
                      aria-label={t('messages.unpin')}
                      size="sm"
                      variant="ghost"
                      className="opacity-0 group-hover:opacity-100 group-focus-within:opacity-100"
                      onClick={() => handleUnpin(message.Id)}
                    >
                      <PinOff className="size-3.5" aria-hidden="true" />
                    </IconButton>
                  </Tooltip>
                </div>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}
