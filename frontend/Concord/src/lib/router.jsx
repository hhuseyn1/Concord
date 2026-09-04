import { createBrowserRouter } from 'react-router-dom'
import { RequireAuth } from '../app/RequireAuth'
import { NotFoundPlaceholder, ServerPlaceholder } from '../app/routePlaceholders'
import { LandingScreen } from '../features/landing/LandingScreen'
import {
  AdminDashboardScreen,
  CabinetRoot,
  ChannelView,
  DirectMessageView,
  ForgotPasswordScreen,
  FriendsScreen,
  KitchenSink,
  LinkDeviceScreen,
  LoginScreen,
  RegisterScreen,
  ResetPasswordScreen,
  SettingsScreen,
} from './routeLazy'
import { withSuspense } from './withSuspense'

export const router = createBrowserRouter([
  { path: '/', element: <LandingScreen /> },
  { path: '/login', element: withSuspense(<LoginScreen />) },
  { path: '/register', element: withSuspense(<RegisterScreen />) },
  { path: '/forgot-password', element: withSuspense(<ForgotPasswordScreen />) },
  { path: '/reset-password', element: withSuspense(<ResetPasswordScreen />) },
  {
    element: <RequireAuth />,
    children: [
      { path: 'link', element: withSuspense(<LinkDeviceScreen />) },
      {
        path: 'cabinet',
        element: withSuspense(<CabinetRoot />),
        children: [
          { index: true, element: withSuspense(<FriendsScreen />) },
          { path: 'servers/:serverId', element: <ServerPlaceholder /> },
          { path: 'servers/:serverId/channels/:channelId', element: withSuspense(<ChannelView />) },
          { path: 'dm/:conversationId', element: withSuspense(<DirectMessageView />) },
          { path: 'settings', element: withSuspense(<SettingsScreen />) },
          { path: 'admin', element: withSuspense(<AdminDashboardScreen />) },
        ],
      },
    ],
  },
  ...(import.meta.env.DEV ? [{ path: '/__kitchen-sink', element: withSuspense(<KitchenSink />) }] : []),
  { path: '*', element: <NotFoundPlaceholder /> },
])
