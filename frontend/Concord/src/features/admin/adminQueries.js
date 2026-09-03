import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import * as adminService from '../../api/adminService'
import { authKeys } from '../../app/authKeys'

const USERS_PAGE_SIZE = 20

export const adminKeys = {
  all: ['admin'],
  overview: () => [...adminKeys.all, 'overview'],
  users: (search) => [...adminKeys.all, 'users', search ?? ''],
}

export function useAdminOverview() {
  return useQuery({
    queryKey: adminKeys.overview(),
    queryFn: adminService.getOverview,
  })
}

export function useAdminUsers(page, search) {
  return useQuery({
    queryKey: [...adminKeys.users(search), page],
    queryFn: () => adminService.getUsers(page, USERS_PAGE_SIZE, search),
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
