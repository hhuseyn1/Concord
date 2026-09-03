import { useInfiniteQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import * as notificationsService from '../../api/notificationsService'

const NOTIFICATIONS_PAGE_SIZE = 20

export const notificationsKeys = {
  all: ['notifications'],
  list: () => [...notificationsKeys.all, 'list'],
}

export function useNotificationsList({ enabled = true } = {}) {
  return useInfiniteQuery({
    queryKey: notificationsKeys.list(),
    queryFn: ({ pageParam }) =>
      notificationsService.getNotifications({ page: pageParam, pageSize: NOTIFICATIONS_PAGE_SIZE }),
    initialPageParam: 1,
    getNextPageParam: (lastPage) => {
      const loaded = lastPage.Page * lastPage.PageSize
      return loaded < lastPage.TotalCount ? lastPage.Page + 1 : undefined
    },
    enabled,
  })
}

export function flattenNotificationPages(pages) {
  return pages?.flatMap((page) => page.Items) ?? []
}

export function useMarkNotificationReadMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (notificationId) => notificationsService.markNotificationRead(notificationId),
    onSuccess: (_, notificationId) => {
      patchNotificationsCache(queryClient, (item) =>
        item.Id === notificationId && !item.IsRead
          ? { ...item, IsRead: true, ReadAt: item.ReadAt ?? new Date().toISOString() }
          : item,
      )
    },
  })
}

export function useMarkAllNotificationsReadMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: () => notificationsService.markAllNotificationsRead(),
    onSuccess: () => {
      patchNotificationsCache(queryClient, (item) =>
        item.IsRead ? item : { ...item, IsRead: true, ReadAt: item.ReadAt ?? new Date().toISOString() },
      )
    },
  })
}

function patchNotificationsCache(queryClient, mapItem) {
  queryClient.setQueryData(notificationsKeys.list(), (data) => {
    if (!data) return data
    return {
      ...data,
      pages: data.pages.map((page) => ({ ...page, Items: page.Items.map(mapItem) })),
    }
  })
}
