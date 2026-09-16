import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import * as adminService from '../../api/adminService'
import { authKeys } from '../../app/authKeys'

const USERS_PAGE_SIZE = 20
const SUBSCRIPTIONS_PAGE_SIZE = 20

export const adminKeys = {
  all: ['admin'],
  overview: () => [...adminKeys.all, 'overview'],
  overviewCharts: (fromUtc, toUtc) => [...adminKeys.all, 'overviewCharts', fromUtc ?? '', toUtc ?? ''],
  userGrowth: (year) => [...adminKeys.all, 'userGrowth', year],
  users: (search, sortBy, sortDirection) => [...adminKeys.all, 'users', search ?? '', sortBy ?? '', sortDirection ?? ''],
  subscriptions: (status, search, sortBy, sortDirection, fromUtc, toUtc) => [
    ...adminKeys.all,
    'subscriptions',
    status ?? '',
    search ?? '',
    sortBy ?? '',
    sortDirection ?? '',
    fromUtc ?? '',
    toUtc ?? '',
  ],
}

export function useAdminOverview() {
  return useQuery({
    queryKey: adminKeys.overview(),
    queryFn: adminService.getOverview,
  })
}

export function useAdminOverviewCharts(fromUtc, toUtc) {
  return useQuery({
    queryKey: adminKeys.overviewCharts(fromUtc, toUtc),
    queryFn: () => adminService.getOverviewCharts(fromUtc, toUtc),
  })
}

export function useAdminUserGrowth(year) {
  return useQuery({
    queryKey: adminKeys.userGrowth(year),
    queryFn: () => adminService.getUserGrowth(year),
  })
}

export function useAdminUsers(page, search, sortBy, sortDirection) {
  return useQuery({
    queryKey: [...adminKeys.users(search, sortBy, sortDirection), page],
    queryFn: () => adminService.getUsers(page, USERS_PAGE_SIZE, search, sortBy, sortDirection),
    placeholderData: (previousData) => previousData,
  })
}

export function useAdminSubscriptions(page, status, search, sortBy, sortDirection, fromUtc, toUtc) {
  return useQuery({
    queryKey: [...adminKeys.subscriptions(status, search, sortBy, sortDirection, fromUtc, toUtc), page],
    queryFn: () =>
      adminService.getSubscriptions(page, SUBSCRIPTIONS_PAGE_SIZE, status, search, sortBy, sortDirection, fromUtc, toUtc),
    placeholderData: (previousData) => previousData,
  })
}

function useInvalidateUsersAndOverview() {
  const queryClient = useQueryClient()
  return () => {
    queryClient.invalidateQueries({ queryKey: adminKeys.all })
  }
}

export function useDisableUserMutation() {
  const invalidate = useInvalidateUsersAndOverview()
  return useMutation({
    mutationFn: (userId) => adminService.disableUser(userId),
    onSuccess: invalidate,
  })
}

export function useEnableUserMutation() {
  const invalidate = useInvalidateUsersAndOverview()
  return useMutation({
    mutationFn: (userId) => adminService.enableUser(userId),
    onSuccess: invalidate,
  })
}

export function useSetUserRoleMutation() {
  const invalidate = useInvalidateUsersAndOverview()
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ userId, role }) => adminService.setUserRole(userId, role),
    onSuccess: (_result, { userId, role }) => {
      invalidate()
      queryClient.setQueryData(authKeys.me, (me) => (me?.Id === userId ? { ...me, Role: role } : me))
    },
  })
}
