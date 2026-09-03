import { ArrowDown, MessageSquare } from 'lucide-react'
import { forwardRef, useEffect, useImperativeHandle, useLayoutEffect, useMemo, useRef, useState } from 'react'
import { Button } from '../../components/ui/Button'
import { IconButton } from '../../components/ui/IconButton'
import { EmptyState } from '../../components/ui/EmptyState'
import { ScrollArea } from '../../components/ui/ScrollArea'
import { Skeleton } from '../../components/ui/Skeleton'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import {
  flattenMessagePages,
  useDeleteMessageMutation,
  useEditMessageMutation,
  useForwardMessageMutation,
  usePinMessageMutation,
  useToggleReactionMutation,
  useUnpinMessageMutation,
} from './messagesQueries'
import { mapDeleteMessageError, mapForwardMessageError, mapPinMessageError, mapToggleReactionError } from './messagesErrors'
import { MessageItem } from './MessageItem'
import { SelectionToolbar } from './SelectionToolbar'
import { useMessageSelection } from './useMessageSelection'

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

export const MessageList = forwardRef(function MessageList(
  { serverId, channelId, currentUserId, pages, isLoading, hasNextPage, isFetchingNextPage, fetchNextPage, onReply },
  ref,
) {
  const viewportRef = useRef(null)
  const isNearBottomRef = useRef(true)
  const [isNearBottom, setIsNearBottom] = useState(true)
  const prevPageCountRef = useRef(0)
  const prevNewestIdRef = useRef(undefined)
  const pendingOlderLoadRef = useRef(false)
  const scrollHeightBeforeLoadRef = useRef(0)

  const editMutation = useEditMessageMutation(serverId, channelId)
  const deleteMutation = useDeleteMessageMutation(serverId, channelId)
  const toggleReactionMutation = useToggleReactionMutation(serverId, channelId)
  const pinMutation = usePinMessageMutation(serverId, channelId)
  const unpinMutation = useUnpinMessageMutation(serverId, channelId)
  const forwardMutation = useForwardMessageMutation(serverId, channelId)

  const messages = useMemo(() => flattenMessagePages(pages), [pages])
  const groups = useMemo(() => groupMessages(messages), [messages])
  const selection = useMessageSelection(messages)
  const messageById = useMemo(() => new Map(messages.map((message) => [message.Id, message])), [messages])

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
      toast({ variant: 'danger', title: 'Could not remove message', description: mapDeleteMessageError(error) })
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
      toast({ variant: 'danger', title: 'Could not pin message', description: mapPinMessageError(error) })
      throw error
    }
  }

  const handleUnpin = async (messageId) => {
    try {
      await unpinMutation.mutateAsync(messageId)
    } catch (error) {
      toast({ variant: 'danger', title: 'Could not unpin message', description: mapPinMessageError(error) })
      throw error
    }
  }

  const handleForward = async (messageId, target) => {
    try {
      await forwardMutation.mutateAsync({ messageId, target })
      toast({ variant: 'success', title: 'Message forwarded' })
    } catch (error) {
      toast({ variant: 'danger', title: 'Could not forward message', description: mapForwardMessageError(error) })
      throw error
    }
  }

  const handleRemoveSelected = async () => {
    await Promise.allSettled(Array.from(selection.selectedIds).map((messageId) => handleDelete(messageId)))
  }

  if (isLoading) {
    return <ListSkeleton />
  }

  if (messages.length === 0) {
    return (
      <div className="flex flex-1 items-center justify-center p-8">
        <EmptyState
          icon={MessageSquare}
          title="No messages yet"
          description="Say something to get the conversation started."
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
              <p className="text-xs text-fg-muted">You've reached the beginning of this channel.</p>
            )}
          </div>

          {groups.map((group) =>
            group.messages.map((message, index) => (
              <MessageItem
                key={message.Id}
                message={message}
                showHeader={index === 0}
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
                sourceServerId={serverId}
                sourceChannelId={channelId}
              />
            )),
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
