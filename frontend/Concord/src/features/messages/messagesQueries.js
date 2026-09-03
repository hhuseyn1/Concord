import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import * as messagesService from '../../api/messagesService'

const MESSAGES_PAGE_SIZE = 30

export const messagesKeys = {
  all: ['messages'],
  list: (serverId, channelId) => [...messagesKeys.all, serverId, channelId],
  pinned: (serverId, channelId) => [...messagesKeys.all, serverId, channelId, 'pinned'],
}

export function useMessages(serverId, channelId) {
  return useInfiniteQuery({
    queryKey: messagesKeys.list(serverId, channelId),
    queryFn: ({ pageParam }) =>
      messagesService.getMessages(serverId, channelId, { page: pageParam, pageSize: MESSAGES_PAGE_SIZE }),
    initialPageParam: 1,
    getNextPageParam: (lastPage) => {
      const loaded = lastPage.Page * lastPage.PageSize
      return loaded < lastPage.TotalCount ? lastPage.Page + 1 : undefined
    },
    enabled: Boolean(serverId) && Boolean(channelId),
  })
}

export function flattenMessagePages(pages) {
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

function insertMessageIntoCache(queryClient, serverId, channelId, message) {
  queryClient.setQueryData(messagesKeys.list(serverId, channelId), (data) => {
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

function updateMessageInCache(queryClient, serverId, channelId, message) {
  queryClient.setQueryData(messagesKeys.list(serverId, channelId), (data) => {
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

function removeMessageFromCache(queryClient, serverId, channelId, messageId) {
  queryClient.setQueryData(messagesKeys.list(serverId, channelId), (data) => {
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

export const messagesCache = {
  insert: insertMessageIntoCache,
  update: updateMessageInCache,
  remove: removeMessageFromCache,
}

export function useSendMessageMutation(serverId, channelId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (data) => messagesService.sendMessage(serverId, channelId, data),
    onSuccess: (message) => insertMessageIntoCache(queryClient, serverId, channelId, message),
  })
}

export function useEditMessageMutation(serverId, channelId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ messageId, content }) => messagesService.editMessage(serverId, channelId, messageId, content),
    onSuccess: (message) => updateMessageInCache(queryClient, serverId, channelId, message),
  })
}

export function useToggleReactionMutation(serverId, channelId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ messageId, emoji }) => messagesService.toggleReaction(serverId, channelId, messageId, emoji),
    onSuccess: (message) => updateMessageInCache(queryClient, serverId, channelId, message),
  })
}

export function usePinnedMessages(serverId, channelId, { enabled = true } = {}) {
  return useQuery({
    queryKey: messagesKeys.pinned(serverId, channelId),
    queryFn: () => messagesService.getPinnedMessages(serverId, channelId),
    enabled: enabled && Boolean(serverId) && Boolean(channelId),
  })
}

export function usePinMessageMutation(serverId, channelId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (messageId) => messagesService.pinMessage(serverId, channelId, messageId),
    onSuccess: (message) => {
      updateMessageInCache(queryClient, serverId, channelId, message)
      queryClient.invalidateQueries({ queryKey: messagesKeys.pinned(serverId, channelId) })
    },
  })
}

export function useUnpinMessageMutation(serverId, channelId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (messageId) => messagesService.unpinMessage(serverId, channelId, messageId),
    onSuccess: (message) => {
      updateMessageInCache(queryClient, serverId, channelId, message)
      queryClient.invalidateQueries({ queryKey: messagesKeys.pinned(serverId, channelId) })
    },
  })
}

export function useForwardMessageMutation(serverId, channelId) {
  return useMutation({
    mutationFn: ({ messageId, target }) => messagesService.forwardMessage(serverId, channelId, messageId, target),
  })
}

export function useDeleteMessageMutation(serverId, channelId) {
  const queryClient = useQueryClient()
  const queryKey = messagesKeys.list(serverId, channelId)
  return useMutation({
    mutationFn: (messageId) => messagesService.deleteMessage(serverId, channelId, messageId),
    onMutate: async (messageId) => {
      await queryClient.cancelQueries({ queryKey })
      const previous = queryClient.getQueryData(queryKey)
      removeMessageFromCache(queryClient, serverId, channelId, messageId)
      return { previous }
    },
    onError: (_error, _messageId, context) => {
      if (context?.previous) queryClient.setQueryData(queryKey, context.previous)
    },
  })
}
