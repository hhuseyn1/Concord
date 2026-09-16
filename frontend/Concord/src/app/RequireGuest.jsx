import { Navigate, Outlet } from 'react-router-dom'
import * as tokenStorage from '../api/tokenStorage'

export function RequireGuest() {
  if (tokenStorage.isAuthenticated()) {
    return <Navigate to="/cabinet" replace />
  }

  return <Outlet />
}
