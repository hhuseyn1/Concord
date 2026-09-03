import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import * as authService from '../../api/authService'
import * as sessionsService from '../../api/sessionsService'
import * as usersService from '../../api/usersService'
import { authKeys } from '../../app/authKeys'

export const sessionsKeys = {
  all: ['sessions'],
}

export function useUpdateProfileMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: usersService.updateMe,
    onSuccess: (data) => {
      queryClient.setQueryData(authKeys.me, data)
    },
  })
}

export function useUpdatePreferencesMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: usersService.updateMyPreferences,
    onSuccess: (data) => {
      queryClient.setQueryData(authKeys.me, data)
    },
  })
}

export function useUpdatePrivacyMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: usersService.updateMyPrivacy,
    onSuccess: (data) => {
      queryClient.setQueryData(authKeys.me, data)
    },
  })
}

export function useUpdateCustomStatusMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: usersService.updateMyCustomStatus,
    onSuccess: (data) => {
      queryClient.setQueryData(authKeys.me, data)
    },
  })
}

export function useChangePasswordMutation() {
  return useMutation({
    mutationFn: authService.changePassword,
  })
}

export function useSessionsList() {
  return useQuery({
    queryKey: sessionsKeys.all,
    queryFn: sessionsService.getSessions,
  })
}

export function useRevokeSessionMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: sessionsService.revokeSession,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: sessionsKeys.all }),
  })
}

export function useRevokeOtherSessionsMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: sessionsService.revokeOtherSessions,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: sessionsKeys.all }),
  })
}

export const twoFactorKeys = {
  status: ['twoFactor', 'status'],
}

export function useTwoFactorStatus() {
  return useQuery({
    queryKey: twoFactorKeys.status,
    queryFn: authService.getTwoFactorStatus,
  })
}

export function useStartTwoFactorSetupMutation() {
  return useMutation({
    mutationFn: authService.startTwoFactorSetup,
  })
}

export function useEnableTwoFactorMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (code) => authService.enableTwoFactor(code),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: twoFactorKeys.status }),
  })
}

export function useDisableTwoFactorMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (data) => authService.disableTwoFactor(data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: twoFactorKeys.status }),
  })
}

export function useRegenerateRecoveryCodesMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (password) => authService.regenerateRecoveryCodes(password),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: twoFactorKeys.status }),
  })
}
