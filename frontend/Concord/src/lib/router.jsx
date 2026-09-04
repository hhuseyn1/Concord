import { createBrowserRouter } from 'react-router-dom'
import { RequireAuth } from '../app/RequireAuth'
import { NotFoundPlaceholder, ServerPlaceholder } from '../app/routePlaceholders'
import { AppShell } from '../components/layout/AppShell'
import { KitchenSink } from '../dev/KitchenSink'
import { AdminDashboardScreen } from '../features/admin/AdminDashboardScreen'
import { ForgotPasswordScreen } from '../features/auth/ForgotPasswordScreen'
import { LinkDeviceScreen } from '../features/auth/LinkDeviceScreen'
import { LoginScreen } from '../features/auth/LoginScreen'
import { RegisterScreen } from '../features/auth/RegisterScreen'
import { ResetPasswordScreen } from '../features/auth/ResetPasswordScreen'
import { DirectMessageView } from '../features/directMessages/DirectMessageView'
import { FriendsScreen } from '../features/friends/FriendsScreen'
import { LandingScreen } from '../features/landing/LandingScreen'
import { ChannelView } from '../features/messages/ChannelView'
import { SettingsScreen } from '../features/settings/SettingsScreen'

export const router = createBrowserRouter([
  { path: '/', element: <LandingScreen /> },
  { path: '/login', element: <LoginScreen /> },
  { path: '/register', element: <RegisterScreen /> },
  { path: '/forgot-password', element: <ForgotPasswordScreen /> },
  { path: '/reset-password', element: <ResetPasswordScreen /> },
  {
    element: <RequireAuth />,
    children: [
      { path: 'link', element: <LinkDeviceScreen /> },
      {
        element: <AppShell />,
        children: [
          { index: true, element: <FriendsScreen /> },
          { path: 'servers/:serverId', element: <ServerPlaceholder /> },
          { path: 'servers/:serverId/channels/:channelId', element: <ChannelView /> },
          { path: 'dm/:conversationId', element: <DirectMessageView /> },
          { path: 'settings', element: <SettingsScreen /> },
          { path: 'admin', element: <AdminDashboardScreen /> },
        ],
      },
    ],
  },
  ...(import.meta.env.DEV ? [{ path: '/__kitchen-sink', element: <KitchenSink /> }] : []),
  { path: '*', element: <NotFoundPlaceholder /> },
])
