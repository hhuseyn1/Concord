import { useMutation, useQuery } from '@tanstack/react-query'
import * as billingService from '../../api/billingService'

export const billingKeys = {
  subscription: ['billing', 'subscription'],
}

export function useCreateCheckoutSessionMutation() {
  return useMutation({
    mutationFn: billingService.createCheckoutSession,
  })
}

export function useSubscriptionQuery() {
  return useQuery({
    queryKey: billingKeys.subscription,
    queryFn: billingService.getSubscription,
    staleTime: 5 * 60 * 1000,
  })
}

export function useCreatePortalSessionMutation() {
  return useMutation({
    mutationFn: billingService.createPortalSession,
  })
}
