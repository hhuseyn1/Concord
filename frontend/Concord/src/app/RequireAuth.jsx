import { useEffect, useState } from 'react'
import { Navigate, Outlet, useLocation } from 'react-router-dom'
import * as tokenStorage from '../api/tokenStorage'

export function RequireAuth() {
  const [isAuthenticated, setIsAuthenticated] = useState(() => tokenStorage.isAuthenticated())
  const location = useLocation()

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
