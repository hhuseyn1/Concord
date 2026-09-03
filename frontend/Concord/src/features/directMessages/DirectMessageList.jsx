import { useQueryClient } from '@tanstack/react-query'
import { ArrowDown, MessageSquare } from 'lucide-react'
import { forwardRef, useEffect, useImperativeHandle, useLayoutEffect, useMemo, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { IconButton } from '../../components/ui/IconButton'
import { ScrollArea } from '../../components/ui/ScrollArea'
import { Skeleton } from '../../components/ui/Skeleton'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { useDirectMessagesLive } from '../../hooks/useDirectMessagesLive'
import { MessageItem } from '../messages/MessageItem'
import { SelectionToolbar } from '../messages/SelectionToolbar'
import { useMessageSelection } from '../messages/useMessageSelection'
import { CallEventRow } from './CallEventRow'
import { useConversationCalls } from './directCallsQueries'
import { mapDeleteDirectMessageError, mapForwardDirectMessageError, mapPinDirectMessageError, mapToggleReactionError } from './directMessagesErrors'
import {
  directMessagesKeys,
  flattenConversationPages,
  flattenDirectMessagePages,
  useDeleteDirectMessageMutation,
  useEditDirectMessageMutation,
  useForwardDirectMessageMutation,
  usePinDirectMessageMutation,
  useToggleDirectMessageReactionMutation,
  useUnpinDirectMessageMutation,
} from './directMessagesQueries'

const GROUP_WINDOW_MS = 5 * 60 * 1000
const NEAR_BOTTOM_THRESHOLD_PX = 150

function groupMessages(messages) {
  const groups = []
  for (const message of messages) {
    const lastGroup = groups[groups.length - 1]
    const lastMessage = lastGroup?.messages[lastGroup.messages.length - 1]
    const sameSender = lastMessage && lastMessage.Sender?.Id === message.Sender?.Id
    const withinWindow =
      lastMessage && Math.abs(new Date(message.Created) - new Date(lastMessage.Created)) < GROUP_WINDOW_MS
    if (lastGroup && sameSender && withinWindow) {
      lastGroup.messages.push(message)
    } else {
      groups.push({ key: message.Id, messages: [message] })
    }
  }
  return groups
}

function ListSkeleton() {
  return (
    <div className="flex flex-col gap-4 px-4 py-4">
      {Array.from({ length: 6 }, (_, index) => (
        <div key={index} className="flex items-start gap-3">
          <Skeleton className="size-10 shrink-0 rounded-full" />
          <div className="flex min-w-0 flex-1 flex-col gap-1.5">
            <Skeleton className="h-3.5 w-32" />
            <Skeleton className="h-3.5 w-3/5" />
          </div>
        </div>
      ))}
    </div>
  )
}

export const DirectMessageList = forwardRef(function DirectMessageList(
  { conversationId, currentUserId, otherUserDisplayName, pages, isLoading, hasNextPage, isFetchingNextPage, fetchNextPage, onReply },
  ref,
) {
  const { t } = useTranslation()
  const queryClient = useQueryClient()
  const { readReceiptsByConversation } = useDirectMessagesLive()
  const viewportRef = useRef(null)
  const isNearBottomRef = useRef(true)
  const [isNearBottom, setIsNearBottom] = useState(true)
  const prevPageCountRef = useRef(0)
  const prevNewestIdRef = useRef(undefined)
  const pendingOlderLoadRef = useRef(false)
  const scrollHeightBeforeLoadRef = useRef(0)

  const editMutation = useEditDirectMessageMutation(conversationId)
  const deleteMutation = useDeleteDirectMessageMutation(conversationId)
  const toggleReactionMutation = useToggleDirectMessageReactionMutation(conversationId)
  const pinMutation = usePinDirectMessageMutation(conversationId)
  const unpinMutation = useUnpinDirectMessageMutation(conversationId)
  const forwardMutation = useForwardDirectMessageMutation(conversationId)

  const messages = useMemo(() => flattenDirectMessagePages(pages), [pages])
  const groups = useMemo(() => groupMessages(messages), [messages])
  const selection = useMessageSelection(messages)
  const messageById = useMemo(() => new Map(messages.map((message) => [message.Id, message])), [messages])

  const [unreadCountAtOpen] = useState(() => {
    const cached = queryClient.getQueryData(directMessagesKeys.conversations())
    const conversation = flattenConversationPages(cached?.pages).find((item) => item.Id === conversationId)
    return conversation?.UnreadCount ?? 0
  })
  const firstUnreadMessageId =
    unreadCountAtOpen > 0 && unreadCountAtOpen < messages.length
      ? messages[messages.length - unreadCountAtOpen]?.Id
      : undefined

  const lastOwnMessageId = useMemo(() => {
    for (let i = messages.length - 1; i >= 0; i--) {
      if (messages[i].Sender?.Id === currentUserId) return messages[i].Id
    }
    return undefined
  }, [messages, currentUserId])
  const otherReadAt = readReceiptsByConversation[conversationId]
  const lastOwnMessage = lastOwnMessageId ? messageById.get(lastOwnMessageId) : undefined
  const showReadReceipt =
    Boolean(lastOwnMessage) && Boolean(otherReadAt) && new Date(otherReadAt) >= new Date(lastOwnMessage.Created)

  const { data: calls } = useConversationCalls(conversationId)
  const timeline = useMemo(() => {
    const groupEntries = groups.map((group) => ({
      kind: 'group',
      key: `group:${group.key}`,
      created: group.messages[0].Created,
      group,
    }))
    const callEntries = (calls ?? []).map((call) => ({
      kind: 'call',
      key: `call:${call.Id}`,
      created: call.Created,
      call,
    }))
    return [...groupEntries, ...callEntries].sort((a, b) => new Date(a.created) - new Date(b.created))
  }, [groups, calls])

  useImperativeHandle(ref, () => ({
    scrollToBottom: () => {
      const el = viewportRef.current
      if (el) el.scrollTop = el.scrollHeight
    },
  }))

  useEffect(() => {
    const el = viewportRef.current
    if (!el) return undefined
    const handleScroll = () => {
      const nearBottom = el.scrollHeight - el.scrollTop - el.clientHeight < NEAR_BOTTOM_THRESHOLD_PX
      isNearBottomRef.current = nearBottom
      setIsNearBottom(nearBottom)
    }
    handleScroll()
    el.addEventListener('scroll', handleScroll)
    return () => el.removeEventListener('scroll', handleScroll)
  }, [])

  const handleLoadOlder = async () => {
    const el = viewportRef.current
    if (el) {
      scrollHeightBeforeLoadRef.current = el.scrollHeight
      pendingOlderLoadRef.current = true
    }
    const result = await fetchNextPage()
    if (result.isError) {
      pendingOlderLoadRef.current = false
    }
  }

  useLayoutEffect(() => {
    const el = viewportRef.current
    const pageCount = pages?.length ?? 0
    if (el && pendingOlderLoadRef.current && pageCount > prevPageCountRef.current) {
      el.scrollTop += el.scrollHeight - scrollHeightBeforeLoadRef.current
      pendingOlderLoadRef.current = false
    }
    prevPageCountRef.current = pageCount
  }, [pages])

  useLayoutEffect(() => {
    const el = viewportRef.current
    if (!el) return
    const newestId = messages[messages.length - 1]?.Id
    const isFirstLoad = prevNewestIdRef.current === undefined && newestId !== undefined
    const appendedWhileNearBottom =
      newestId !== undefined &&
      newestId !== prevNewestIdRef.current &&
      !pendingOlderLoadRef.current &&
      isNearBottomRef.current
    if (isFirstLoad || appendedWhileNearBottom) {
      el.scrollTop = el.scrollHeight
    }
    prevNewestIdRef.current = newestId
  }, [messages])

  const handleEdit = async (messageId, content) => {
    await editMutation.mutateAsync({ messageId, content })
  }

  const handleDelete = async (messageId) => {
    try {
      await deleteMutation.mutateAsync(messageId)
    } catch (error) {
      toast({ variant: 'danger', title: 'Could not remove message', description: mapDeleteDirectMessageError(error) })
    }
  }

  const handleToggleReaction = async (messageId, emoji) => {
    try {
      await toggleReactionMutation.mutateAsync({ messageId, emoji })
    } catch (error) {
      toast({ variant: 'danger', title: 'Could not react to message', description: mapToggleReactionError(error) })
    }
  }

  const handlePin = async (messageId) => {
    try {
      await pinMutation.mutateAsync(messageId)
    } catch (error) {
      toast({ variant: 'danger', title: 'Could not pin message', description: mapPinDirectMessageError(error) })
      throw error
    }
  }

  const handleUnpin = async (messageId) => {
    try {
      await unpinMutation.mutateAsync(messageId)
    } catch (error) {
      toast({ variant: 'danger', title: 'Could not unpin message', description: mapPinDirectMessageError(error) })
      throw error
    }
  }

  const handleForward = async (messageId, target) => {
    try {
      await forwardMutation.mutateAsync({ messageId, target })
      toast({ variant: 'success', title: 'Message forwarded' })
    } catch (error) {
      toast({ variant: 'danger', title: 'Could not forward message', description: mapForwardDirectMessageError(error) })
      throw error
    }
  }

  const handleRemoveSelected = async () => {
    await Promise.allSettled(Array.from(selection.selectedIds).map((messageId) => handleDelete(messageId)))
  }

  if (isLoading) {
    return <ListSkeleton />
  }

  if (messages.length === 0 && timeline.length === 0) {
    return (
      <div className="flex flex-1 items-center justify-center p-8">
        <EmptyState
          icon={MessageSquare}
          title="No messages yet"
          description="Say hi to start the conversation."
        />
      </div>
    )
  }

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      {selection.selectionMode && (
        <SelectionToolbar
          selectedCount={selection.selectedCount}
          allSelected={selection.allSelected}
          onToggleSelectAll={selection.toggleSelectAll}
          onRemoveSelected={handleRemoveSelected}
          onCancel={selection.exitSelectionMode}
        />
      )}
      <div className="relative min-h-0 flex-1">
      <ScrollArea className="h-full" viewportRef={viewportRef}>
        <div className="flex flex-col pb-4">
          <div className="flex justify-center py-3">
            {hasNextPage ? (
              <Button variant="secondary" size="sm" onClick={handleLoadOlder} disabled={isFetchingNextPage}>
                {isFetchingNextPage && <Spinner size="sm" />}
                {isFetchingNextPage ? 'Loading…' : 'Load older messages'}
              </Button>
            ) : (
              <p className="text-xs text-fg-muted">This is the beginning of your conversation.</p>
            )}
          </div>

          {timeline.map((entry) =>
            entry.kind === 'call' ? (
              <CallEventRow
                key={entry.key}
                call={entry.call}
                currentUserId={currentUserId}
                otherUserDisplayName={otherUserDisplayName}
              />
            ) : (
              entry.group.messages.map((message, index) => (
                <div key={message.Id}>
                  {message.Id === firstUnreadMessageId && (
                    <div className="my-2 flex items-center gap-2 px-4" aria-hidden="true">
                      <div className="h-px flex-1 bg-danger/40" />
                      <span className="text-xs font-semibold text-danger">{t('messages.newMessages')}</span>
                      <div className="h-px flex-1 bg-danger/40" />
                    </div>
                  )}
                  <MessageItem
                    message={message}
                    showHeader={index === 0 || message.Id === firstUnreadMessageId}
                    isOwn={Boolean(currentUserId) && message.Sender?.Id === currentUserId}
                    onEdit={handleEdit}
                    onDelete={handleDelete}
                    onReply={onReply}
                    replyToMessage={message.ReplyToMessageId ? messageById.get(message.ReplyToMessageId) : undefined}
                    onToggleReaction={handleToggleReaction}
                    selectionMode={selection.selectionMode}
                    selected={selection.selectedIds.has(message.Id)}
                    onToggleSelect={selection.toggleSelect}
                    onEnterSelectionMode={selection.enterSelectionMode}
                    onPin={handlePin}
                    onUnpin={handleUnpin}
                    onForward={handleForward}
                    sourceConversationId={conversationId}
                  />
                  {message.Id === lastOwnMessageId && showReadReceipt && (
                    <p className="px-4 pt-0.5 text-right text-[10px] text-fg-muted">{t('messages.read')}</p>
                  )}
                </div>
              ))
            ),
          )}
        </div>
      </ScrollArea>

      {!isNearBottom && (
        <IconButton
          aria-label="Scroll to bottom"
          variant="secondary"
          className="absolute right-4 bottom-4 shadow-md"
          onClick={() => {
            const el = viewportRef.current
            if (el) el.scrollTop = el.scrollHeight
          }}
        >
          <ArrowDown className="size-4" aria-hidden="true" />
        </IconButton>
      )}
      </div>
    </div>
  )
})
