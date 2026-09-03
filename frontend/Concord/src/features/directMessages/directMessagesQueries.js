import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import * as directMessagesService from '../../api/directMessagesService'

const CONVERSATIONS_PAGE_SIZE = 30
const DM_PAGE_SIZE = 30

export const directMessagesKeys = {
  all: ['directMessages'],
  conversations: () => [...directMessagesKeys.all, 'conversations'],
  list: (conversationId) => [...directMessagesKeys.all, 'thread', conversationId],
  pinned: (conversationId) => [...directMessagesKeys.all, 'thread', conversationId, 'pinned'],
}

export function useConversations() {
  return useInfiniteQuery({
    queryKey: directMessagesKeys.conversations(),
    queryFn: ({ pageParam }) =>
      directMessagesService.getConversations({ page: pageParam, pageSize: CONVERSATIONS_PAGE_SIZE }),
    initialPageParam: 1,
    getNextPageParam: (lastPage) => {
      const loaded = lastPage.Page * lastPage.PageSize
      return loaded < lastPage.TotalCount ? lastPage.Page + 1 : undefined
    },
  })
}

export function flattenConversationPages(pages) {
  return pages?.flatMap((page) => page.Items) ?? []
}

export function useDirectMessages(conversationId) {
  return useInfiniteQuery({
    queryKey: directMessagesKeys.list(conversationId),
    queryFn: ({ pageParam }) =>
      directMessagesService.getDirectMessages(conversationId, { page: pageParam, pageSize: DM_PAGE_SIZE }),
    initialPageParam: 1,
    getNextPageParam: (lastPage) => {
      const loaded = lastPage.Page * lastPage.PageSize
      return loaded < lastPage.TotalCount ? lastPage.Page + 1 : undefined
    },
    enabled: Boolean(conversationId),
  })
}

export function flattenDirectMessagePages(pages) {
  if (!pages || pages.length === 0) return []
  const result = []
  for (let pageIndex = pages.length - 1; pageIndex >= 0; pageIndex--) {
    const items = pages[pageIndex]?.Items ?? []
    for (let itemIndex = items.length - 1; itemIndex >= 0; itemIndex--) {
      result.push(items[itemIndex])
    }
  }
  return result
}

function insertDirectMessageIntoCache(queryClient, conversationId, message) {
  queryClient.setQueryData(directMessagesKeys.list(conversationId), (data) => {
    if (!data || data.pages.length === 0) return data
    const alreadyPresent = data.pages.some((page) => page.Items.some((item) => item.Id === message.Id))
    if (alreadyPresent) return data

    const [newestPage, ...restPages] = data.pages
    const updatedNewestPage = {
      ...newestPage,
      Items: [message, ...newestPage.Items],
      TotalCount: newestPage.TotalCount + 1,
    }
    return { ...data, pages: [updatedNewestPage, ...restPages] }
  })
}

function updateDirectMessageInCache(queryClient, conversationId, message) {
  queryClient.setQueryData(directMessagesKeys.list(conversationId), (data) => {
    if (!data) return data
    return {
      ...data,
      pages: data.pages.map((page) => ({
        ...page,
        Items: page.Items.map((item) => (item.Id === message.Id ? message : item)),
      })),
    }
  })
}

function removeDirectMessageFromCache(queryClient, conversationId, messageId) {
  queryClient.setQueryData(directMessagesKeys.list(conversationId), (data) => {
    if (!data) return data
    return {
      ...data,
      pages: data.pages.map((page) => {
        const wasPresent = page.Items.some((item) => item.Id === messageId)
        if (!wasPresent) return page
        return {
          ...page,
          Items: page.Items.filter((item) => item.Id !== messageId),
          TotalCount: Math.max(0, page.TotalCount - 1),
        }
      }),
    }
  })
}

function patchConversationsListOnMessage(queryClient, message, { skipUnreadBump = false } = {}) {
  const queryKey = directMessagesKeys.conversations()
  const data = queryClient.getQueryData(queryKey)

  if (!data || data.pages.length === 0) {
    queryClient.invalidateQueries({ queryKey })
    return
  }

  let found = null
  for (const page of data.pages) {
    const match = page.Items.find((item) => item.Id === message.ConversationId)
    if (match) {
      found = match
      break
    }
  }

  if (!found) {
    queryClient.invalidateQueries({ queryKey })
    return
  }

  const updatedConversation = {
    ...found,
    LastMessage: message,
    LastMessageAt: message.Created,
    UnreadCount: skipUnreadBump ? found.UnreadCount : found.UnreadCount + 1,
  }

  queryClient.setQueryData(queryKey, (current) => {
    if (!current) return current
    const [firstPage, ...restPages] = current.pages
    const remainingFirstPageItems = firstPage.Items.filter((item) => item.Id !== updatedConversation.Id)
    const updatedFirstPage = { ...firstPage, Items: [updatedConversation, ...remainingFirstPageItems] }

    return {
      ...current,
      pages: [
        updatedFirstPage,
        ...restPages.map((page) => ({
          ...page,
          Items: page.Items.filter((item) => item.Id !== updatedConversation.Id),
        })),
      ],
    }
  })
}

export const directMessagesCache = {
  insert: insertDirectMessageIntoCache,
  update: updateDirectMessageInCache,
  remove: removeDirectMessageFromCache,
  patchConversationsList: patchConversationsListOnMessage,
}

export function useSendDirectMessageMutation(conversationId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (data) => directMessagesService.sendDirectMessage(conversationId, data),
    onSuccess: (message) => {
      insertDirectMessageIntoCache(queryClient, conversationId, message)
      patchConversationsListOnMessage(queryClient, message, { skipUnreadBump: true })
    },
  })
}

export function useEditDirectMessageMutation(conversationId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ messageId, content }) => directMessagesService.editDirectMessage(conversationId, messageId, content),
    onSuccess: (message) => updateDirectMessageInCache(queryClient, conversationId, message),
  })
}

export function useToggleDirectMessageReactionMutation(conversationId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ messageId, emoji }) => directMessagesService.toggleDirectMessageReaction(conversationId, messageId, emoji),
    onSuccess: (message) => updateDirectMessageInCache(queryClient, conversationId, message),
  })
}

export function usePinnedDirectMessages(conversationId, { enabled = true } = {}) {
  return useQuery({
    queryKey: directMessagesKeys.pinned(conversationId),
    queryFn: () => directMessagesService.getPinnedDirectMessages(conversationId),
    enabled: enabled && Boolean(conversationId),
  })
}

export function usePinDirectMessageMutation(conversationId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (messageId) => directMessagesService.pinDirectMessage(conversationId, messageId),
    onSuccess: (message) => {
      updateDirectMessageInCache(queryClient, conversationId, message)
      queryClient.invalidateQueries({ queryKey: directMessagesKeys.pinned(conversationId) })
    },
  })
}

export function useUnpinDirectMessageMutation(conversationId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (messageId) => directMessagesService.unpinDirectMessage(conversationId, messageId),
    onSuccess: (message) => {
      updateDirectMessageInCache(queryClient, conversationId, message)
      queryClient.invalidateQueries({ queryKey: directMessagesKeys.pinned(conversationId) })
    },
  })
}

export function useForwardDirectMessageMutation(conversationId) {
  return useMutation({
    mutationFn: ({ messageId, target }) => directMessagesService.forwardDirectMessage(conversationId, messageId, target),
  })
}

export function useDeleteDirectMessageMutation(conversationId) {
  const queryClient = useQueryClient()
  const queryKey = directMessagesKeys.list(conversationId)
  return useMutation({
    mutationFn: (messageId) => directMessagesService.deleteDirectMessage(conversationId, messageId),
    onMutate: async (messageId) => {
      await queryClient.cancelQueries({ queryKey })
      const previous = queryClient.getQueryData(queryKey)
      removeDirectMessageFromCache(queryClient, conversationId, messageId)
      return { previous }
    },
    onError: (_error, _messageId, context) => {
      if (context?.previous) queryClient.setQueryData(queryKey, context.previous)
    },
  })
}
