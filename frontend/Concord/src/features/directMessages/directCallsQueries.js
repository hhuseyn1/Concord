import { useQuery, useQueryClient } from '@tanstack/react-query'
import * as directCallsService from '../../api/directCallsService'

const CALLS_PAGE_SIZE = 30

export const directCallsKeys = {
  all: ['directCalls'],
  list: (conversationId) => [...directCallsKeys.all, conversationId],
}

export function useConversationCalls(conversationId) {
  return useQuery({
    queryKey: directCallsKeys.list(conversationId),
    queryFn: () => directCallsService.getCalls(conversationId, { page: 1, pageSize: CALLS_PAGE_SIZE }),
    enabled: Boolean(conversationId),
    select: (data) => data.Items,
  })
}

export function useInvalidateConversationCalls() {
  const queryClient = useQueryClient()
  return (conversationId) => queryClient.invalidateQueries({ queryKey: directCallsKeys.list(conversationId) })
}
