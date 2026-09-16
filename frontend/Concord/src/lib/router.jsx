import { createBrowserRouter } from 'react-router-dom'
import { AdminLayout } from '../app/AdminLayout'
import { RequireAdmin } from '../app/RequireAdmin'
import { RequireAuth } from '../app/RequireAuth'
import { RequireGuest } from '../app/RequireGuest'
import { NotFoundPlaceholder, ServerPlaceholder } from '../app/routePlaceholders'
import { LandingScreen } from '../features/landing/LandingScreen'
import {
  AdminDashboardScreen,
  CabinetRoot,
  ChannelView,
  CheckoutCancelScreen,
  CheckoutSuccessScreen,
  DirectMessageView,
  ForgotPasswordScreen,
  FriendsScreen,
  KitchenSink,
  LinkDeviceScreen,
  LoginScreen,
  RegisterScreen,
  ResetPasswordScreen,
  SettingsScreen,
  VerifyEmailScreen,
} from './routeLazy'
import { withSuspense } from './withSuspense'

export const router = createBrowserRouter([
  { path: '/', element: <LandingScreen /> },
  {
    element: <RequireGuest />,
    children: [{ path: '/login', element: withSuspense(<LoginScreen />) }],
  },
  { path: '/register', element: withSuspense(<RegisterScreen />) },
  { path: '/forgot-password', element: withSuspense(<ForgotPasswordScreen />) },
  { path: '/reset-password', element: withSuspense(<ResetPasswordScreen />) },
  { path: '/verify-email', element: withSuspense(<VerifyEmailScreen />) },
  {
    element: <RequireAuth />,
    children: [
      { path: 'link', element: withSuspense(<LinkDeviceScreen />) },
      {
        element: <RequireAdmin />,
        children: [
          {
            path: 'admin',
            element: <AdminLayout />,
            children: [{ index: true, element: withSuspense(<AdminDashboardScreen />) }],
          },
        ],
      },
      {
        path: 'cabinet',
        element: withSuspense(<CabinetRoot />),
        children: [
          { index: true, element: withSuspense(<FriendsScreen />) },
          { path: 'servers/:serverId', element: <ServerPlaceholder /> },
          { path: 'servers/:serverId/channels/:channelId', element: withSuspense(<ChannelView />) },
          { path: 'dm/:conversationId', element: withSuspense(<DirectMessageView />) },
          { path: 'settings', element: withSuspense(<SettingsScreen />) },
          { path: 'checkout/success', element: withSuspense(<CheckoutSuccessScreen />) },
          { path: 'checkout/cancel', element: withSuspense(<CheckoutCancelScreen />) },
        ],
      },
    ],
  },
  ...(import.meta.env.DEV ? [{ path: '/__kitchen-sink', element: withSuspense(<KitchenSink />) }] : []),
  { path: '*', element: <NotFoundPlaceholder /> },
])
