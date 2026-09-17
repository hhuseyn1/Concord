import { Navigate, Outlet } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

export function RequireAdmin() {
  const { user, isLoading } = useAuth()

  if (isLoading) return null

  if (user?.Role !== 'Admin') {
    return <Navigate to="/cabinet" replace />
  }

  return <Outlet />
}
