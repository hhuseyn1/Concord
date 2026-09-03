import { useQueryClient } from '@tanstack/react-query'
import { useMemo } from 'react'
import { useAuth } from '../../hooks/useAuth'
import { directMessagesKeys, flattenConversationPages, useDirectMessages } from './directMessagesQueries'

export function useOtherUserDisplayName(conversationId) {
  const otherUser = useOtherUserProfile(conversationId)
  if (!otherUser) return undefined
  return otherUser.Username || [otherUser.Name, otherUser.Surname].filter(Boolean).join(' ') || undefined
}

export function useOtherUserProfile(conversationId) {
  const { user } = useAuth()
  const queryClient = useQueryClient()
  const { data } = useDirectMessages(conversationId)

  return useMemo(() => {
    if (!conversationId) return undefined

    const conversationsData = queryClient.getQueryData(directMessagesKeys.conversations())
    const cachedConversation = flattenConversationPages(conversationsData?.pages).find(
      (item) => item.Id === conversationId,
    )
    return (
      cachedConversation?.OtherUser ??
      data?.pages?.flatMap((page) => page.Items)?.find((message) => message.Sender?.Id !== user?.Id)?.Sender
    )
  }, [queryClient, conversationId, data, user?.Id])
}
