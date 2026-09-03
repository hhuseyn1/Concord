import { useRef, useState } from 'react'
import { useParams } from 'react-router-dom'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { useAuth } from '../../hooks/useAuth'
import { useDirectMessagesLive } from '../../hooks/useDirectMessagesLive'
import { TypingIndicator } from '../messages/TypingIndicator'
import { DirectCallBar } from './DirectCallBar'
import { DirectMessageComposer } from './DirectMessageComposer'
import { DirectMessageList } from './DirectMessageList'
import { useDirectMessages } from './directMessagesQueries'
import { mapGetDirectMessagesError } from './directMessagesErrors'
import { useOtherUserDisplayName } from './useOtherUserDisplayName'

const EMPTY_TYPING_SET = new Set()

export function DirectMessageView() {
  const { conversationId } = useParams()
  return <DirectMessageThread key={conversationId} conversationId={conversationId} />
}

function DirectMessageThread({ conversationId }) {
  const { user } = useAuth()
  const listRef = useRef(null)
  const { typingByConversation, notifyTyping, stopTyping } = useDirectMessagesLive()
  const typingUserIds = typingByConversation[conversationId] ?? EMPTY_TYPING_SET
  const [replyingTo, setReplyingTo] = useState(null)

  const { data, isLoading, isError, error, hasNextPage, isFetchingNextPage, fetchNextPage, refetch } =
    useDirectMessages(conversationId)

  const otherUserDisplayName = useOtherUserDisplayName(conversationId)

  if (isError) {
    return (
      <div className="flex flex-1 items-center justify-center p-8">
        <EmptyState
          title="Couldn't load this conversation"
          description={mapGetDirectMessagesError(error)}
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
      <DirectCallBar conversationId={conversationId} />
      <DirectMessageList
        key={conversationId}
        ref={listRef}
        conversationId={conversationId}
        currentUserId={user?.Id}
        otherUserDisplayName={otherUserDisplayName}
        pages={data?.pages}
        isLoading={isLoading}
        hasNextPage={Boolean(hasNextPage)}
        isFetchingNextPage={isFetchingNextPage}
        fetchNextPage={fetchNextPage}
        onReply={setReplyingTo}
      />
      <TypingIndicator typingUserIds={typingUserIds} />
      <DirectMessageComposer
        conversationId={conversationId}
        otherUserDisplayName={otherUserDisplayName}
        onSent={() => listRef.current?.scrollToBottom()}
        onTyping={() => notifyTyping(conversationId)}
        onStopTyping={() => stopTyping(conversationId)}
        replyingTo={replyingTo}
        onCancelReply={() => setReplyingTo(null)}
      />
    </div>
  )
}
