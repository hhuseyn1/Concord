import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import * as rolesService from '../../api/rolesService'
import { hasPermission } from './permissions'

export const rolesKeys = {
  all: ['roles'],
  list: (serverId) => [...rolesKeys.all, serverId, 'list'],
  mine: (serverId) => [...rolesKeys.all, serverId, 'mine'],
  member: (serverId, userId) => [...rolesKeys.all, serverId, 'member', userId],
}

export function useRoles(serverId) {
  return useQuery({
    queryKey: rolesKeys.list(serverId),
    queryFn: () => rolesService.getRoles(serverId),
    enabled: Boolean(serverId),
  })
}

export function useMyServerPermissions(serverId) {
  return useQuery({
    queryKey: rolesKeys.mine(serverId),
    queryFn: () => rolesService.getMyPermissions(serverId),
    enabled: Boolean(serverId),
  })
}

export function useCan(serverId) {
  const { data, isLoading } = useMyServerPermissions(serverId)

  return {
    can: (flag) => hasPermission(data?.Permissions ?? 0, flag),
    isOwner: Boolean(data?.IsOwner),
    highestRolePosition: data?.HighestRolePosition ?? 0,
    isLoading,
  }
}

export function useMemberRoles(serverId, userId) {
  return useQuery({
    queryKey: rolesKeys.member(serverId, userId),
    queryFn: () => rolesService.getMemberRoles(serverId, userId),
    enabled: Boolean(serverId && userId),
  })
}

export function useCreateRoleMutation(serverId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (data) => rolesService.createRole(serverId, data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: rolesKeys.list(serverId) }),
  })
}

export function useUpdateRoleMutation(serverId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ roleId, ...data }) => rolesService.updateRole(serverId, roleId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: rolesKeys.list(serverId) })
      queryClient.invalidateQueries({ queryKey: rolesKeys.mine(serverId) })
    },
  })
}

export function useDeleteRoleMutation(serverId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (roleId) => rolesService.deleteRole(serverId, roleId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: rolesKeys.list(serverId) })
      queryClient.invalidateQueries({ queryKey: rolesKeys.mine(serverId) })
    },
  })
}

export function useAssignRoleMutation(serverId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ userId, roleId }) => rolesService.assignRole(serverId, userId, roleId),
    onSuccess: (_result, { userId }) => {
      queryClient.invalidateQueries({ queryKey: rolesKeys.member(serverId, userId) })
      queryClient.invalidateQueries({ queryKey: rolesKeys.list(serverId) })
    },
  })
}

export function useRemoveRoleMutation(serverId) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ userId, roleId }) => rolesService.removeRole(serverId, userId, roleId),
    onSuccess: (_result, { userId }) => {
      queryClient.invalidateQueries({ queryKey: rolesKeys.member(serverId, userId) })
      queryClient.invalidateQueries({ queryKey: rolesKeys.list(serverId) })
    },
  })
}
