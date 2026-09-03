import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useEffect, useState } from 'react'
import * as tokenStorage from '../api/tokenStorage'
import * as usersService from '../api/usersService'
import { authKeys } from './authKeys'
import { AuthContext } from './AuthContext'

export function AuthProvider({ children }) {
  const [isAuthenticated, setIsAuthenticated] = useState(() => tokenStorage.isAuthenticated())
  const queryClient = useQueryClient()

  useEffect(() => {
    return tokenStorage.subscribe((tokens) => {
      const authed = Boolean(tokens?.accessToken)
      setIsAuthenticated(authed)
      if (!authed) {
        queryClient.removeQueries({ queryKey: authKeys.me })
      }
    })
  }, [queryClient])

  const { data: user, isLoading } = useQuery({
    queryKey: authKeys.me,
    queryFn: usersService.getMe,
    enabled: isAuthenticated,
    staleTime: 5 * 60 * 1000,
  })

  return (
    <AuthContext.Provider
      value={{
        user: isAuthenticated ? (user ?? null) : null,
        isAuthenticated,
        isLoading: isAuthenticated && isLoading,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}
