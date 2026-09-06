import { useEffect, useMemo, useState } from 'react'
import { Navigate, Outlet, useLocation } from 'react-router-dom'
import * as tokenStorage from '../api/tokenStorage'
import { useCapturePendingInviteFromUrl } from '../features/servers/pendingInvite'

export function RequireAuth() {
  const [isAuthenticated, setIsAuthenticated] = useState(() => tokenStorage.isAuthenticated())
  const location = useLocation()
  const searchParams = useMemo(() => new URLSearchParams(location.search), [location.search])
  useCapturePendingInviteFromUrl(searchParams)

  useEffect(() => {
    return tokenStorage.subscribe((tokens) => {
      setIsAuthenticated(Boolean(tokens?.accessToken))
    })
  }, [])

  if (!isAuthenticated) {
    return <Navigate to="/login" replace state={{ from: location }} />
  }

  return <Outlet />
}
