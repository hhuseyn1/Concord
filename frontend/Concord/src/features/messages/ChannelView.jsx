import { useQueryClient } from '@tanstack/react-query'
import { useEffect, useRef, useState } from 'react'
import { useParams } from 'react-router-dom'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { Spinner } from '../../components/ui/Spinner'
import { mapGetChannelsError } from '../channels/channelsErrors'
import { channelsKeys, useChannels } from '../channels/channelsQueries'
import { VoiceChannelView } from '../voice/VoiceChannelView'
import { useAuth } from '../../hooks/useAuth'
import { mapGetMessagesError } from './messagesErrors'
import { useMessages } from './messagesQueries'
import { useMessagesLiveUpdates } from './useMessagesLiveUpdates'
import { MessageComposer } from './MessageComposer'
import { MessageList } from './MessageList'
import { TypingIndicator } from './TypingIndicator'

export function ChannelView() {
  const { serverId, channelId } = useParams()
  const {
    data: channels,
    isLoading: channelsLoading,
    isError: channelsError,
    error: channelsErrorDetail,
    refetch: refetchChannels,
  } = useChannels(serverId)

  if (channelsLoading && !channels) {
    return (
      <div className="flex flex-1 items-center justify-center p-8">
        <Spinner label="Loading channel…" />
      </div>
    )
  }

  if (channelsError && !channels) {
    return (
      <div className="flex flex-1 items-center justify-center p-8">
        <EmptyState
          title="Couldn't load this channel"
          description={mapGetChannelsError(channelsErrorDetail)}
          action={
            <Button variant="secondary" size="sm" onClick={() => refetchChannels()}>
              Try again
            </Button>
          }
        />
      </div>
    )
  }

  const channel = channels?.find((item) => item.Id === channelId)

  if (channel?.Type === 'Voice') {
    return <VoiceChannelView channel={channel} serverId={serverId} channelId={channelId} />
  }

  return <TextChannelView serverId={serverId} channelId={channelId} />
}

function TextChannelView({ serverId, channelId }) {
  const { user } = useAuth()
  const queryClient = useQueryClient()
  const listRef = useRef(null)
  const [replyingTo, setReplyingTo] = useState(null)

  const [prevChannelId, setPrevChannelId] = useState(channelId)
  if (channelId !== prevChannelId) {
    setPrevChannelId(channelId)
    setReplyingTo(null)
  }

  const { typingUserIds, notifyTyping, stopTyping } = useMessagesLiveUpdates(serverId, channelId)

  const {
    data,
    isLoading,
    isError,
    error,
    hasNextPage,
    isFetchingNextPage,
    fetchNextPage,
    refetch,
  } = useMessages(serverId, channelId)

  const hasLoadedFirstPage = Boolean(data?.pages?.length)
  useEffect(() => {
    if (!hasLoadedFirstPage) return
    queryClient.setQueryData(channelsKeys.list(serverId), (channels) =>
      channels?.map((channel) => (channel.Id === channelId ? { ...channel, UnreadCount: 0 } : channel)),
    )
  }, [queryClient, serverId, channelId, hasLoadedFirstPage])

  if (isError) {
    return (
      <div className="flex flex-1 items-center justify-center p-8">
        <EmptyState
          title="Couldn't load messages"
          description={mapGetMessagesError(error)}
          action={
            <Button variant="secondary" size="sm" onClick={() => refetch()}>
              Try again
            </Button>
          }
        />
      </div>
    )
  }

  return (
    <div className="flex h-full min-h-0 flex-col">
      <MessageList
        key={channelId}
        ref={listRef}
        serverId={serverId}
        channelId={channelId}
        currentUserId={user?.Id}
        pages={data?.pages}
        isLoading={isLoading}
        hasNextPage={Boolean(hasNextPage)}
        isFetchingNextPage={isFetchingNextPage}
        fetchNextPage={fetchNextPage}
        onReply={setReplyingTo}
      />
      <TypingIndicator typingUserIds={typingUserIds} />
      <MessageComposer
        serverId={serverId}
        channelId={channelId}
        onSent={() => listRef.current?.scrollToBottom()}
        onTyping={notifyTyping}
        onStopTyping={stopTyping}
        replyingTo={replyingTo}
        onCancelReply={() => setReplyingTo(null)}
      />
    </div>
  )
}
