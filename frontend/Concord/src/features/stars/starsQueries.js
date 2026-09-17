import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import * as starsService from '../../api/starsService'
import { authKeys } from '../../app/authKeys'

const TRANSACTIONS_PAGE_SIZE = 20

export const starsKeys = {
  all: ['stars'],
  config: () => [...starsKeys.all, 'config'],
  wallet: () => [...starsKeys.all, 'wallet'],
  transactions: () => [...starsKeys.all, 'transactions'],
  purchaseStatus: (purchaseId) => [...starsKeys.all, 'purchase', purchaseId, 'status'],
}

export function useStarsConfig() {
  return useQuery({
    queryKey: starsKeys.config(),
    queryFn: starsService.getStarsConfig,
    staleTime: 60 * 60 * 1000,
  })
}

export function useStarsWallet() {
  return useQuery({
    queryKey: starsKeys.wallet(),
    queryFn: starsService.getStarsWallet,
    staleTime: 30 * 1000,
  })
}

export function useStarsTransactions() {
  return useInfiniteQuery({
    queryKey: starsKeys.transactions(),
    queryFn: ({ pageParam }) =>
      starsService.getStarsTransactions({ page: pageParam, pageSize: TRANSACTIONS_PAGE_SIZE }),
    initialPageParam: 1,
    getNextPageParam: (lastPage) => {
      const loaded = lastPage.Page * lastPage.PageSize
      return loaded < lastPage.TotalCount ? lastPage.Page + 1 : undefined
    },
  })
}

export function useTransferStarsMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: starsService.transferStars,
    onSuccess: (result) => {
      queryClient.setQueryData(starsKeys.wallet(), (current) =>
        current ? { ...current, Balance: result.Balance } : current,
      )
      queryClient.invalidateQueries({ queryKey: starsKeys.wallet() })
      queryClient.invalidateQueries({ queryKey: starsKeys.transactions() })
    },
  })
}

export function useActivatePremiumTrialMutation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: starsService.activatePremiumTrial,
    onSuccess: (result) => {
      queryClient.setQueryData(starsKeys.wallet(), (current) =>
        current
          ? {
              ...current,
              Balance: result.Balance,
              PremiumTrialActive: true,
              PremiumTrialExpiresAt: result.PremiumTrialExpiresAt,
              HasActivePremium: true,
            }
          : current,
      )
      queryClient.invalidateQueries({ queryKey: starsKeys.wallet() })
      queryClient.invalidateQueries({ queryKey: starsKeys.transactions() })
      queryClient.invalidateQueries({ queryKey: authKeys.me })
    },
  })
}

export function useCreateStarsCheckoutSessionMutation() {
  return useMutation({
    mutationFn: starsService.createStarsCheckoutSession,
  })
}

export function useStarsPurchaseStatus(purchaseId, { enabled = true, refetchInterval } = {}) {
  return useQuery({
    queryKey: starsKeys.purchaseStatus(purchaseId),
    queryFn: () => starsService.getStarsPurchaseStatus(purchaseId),
    enabled: Boolean(purchaseId) && enabled,
    refetchInterval,
    gcTime: 0,
    retry: false,
  })
}
