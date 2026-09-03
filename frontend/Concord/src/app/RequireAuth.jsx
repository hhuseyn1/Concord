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
    // The root path is the app's authenticated home (see ServerRail/ChannelSidebar's `to="/"`
    // links) - a signed-out visitor landing there sees the marketing page instead of being
    // dropped straight into a login form. Every other protected route still bounces to /login
    // as before, including the post-login redirect back to where they were headed.
    const redirectTo = location.pathname === '/' ? '/welcome' : '/login'
    return <Navigate to={redirectTo} replace state={{ from: location }} />
  }

  return <Outlet />
}
