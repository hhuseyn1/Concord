import { Navigate, Outlet } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

// Composed as a child of `RequireAuth`, so "not authenticated" is already handled by the time
// this runs - this only adds the "authenticated but not an Admin" case on top, mirroring
// `RequireAuth`'s loading/redirect/outlet shape.
export function RequireAdmin() {
  const { user, isLoading } = useAuth()

  if (isLoading) return null

  if (user?.Role !== 'Admin') {
    return <Navigate to="/cabinet" replace />
  }

  return <Outlet />
}
