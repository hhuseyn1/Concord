import { lazy } from 'react'

// Everything here is reachable only after navigating away from the public landing page (auth
// screens, the whole authenticated app under /cabinet, the dev kitchen sink) - lazy so a first,
// unauthenticated visit to '/' only downloads LandingScreen instead of the entire app bundle.
export const LoginScreen = lazy(() => import('../features/auth/LoginScreen').then((m) => ({ default: m.LoginScreen })))
export const RegisterScreen = lazy(() =>
  import('../features/auth/RegisterScreen').then((m) => ({ default: m.RegisterScreen })),
)
export const ForgotPasswordScreen = lazy(() =>
  import('../features/auth/ForgotPasswordScreen').then((m) => ({ default: m.ForgotPasswordScreen })),
)
export const ResetPasswordScreen = lazy(() =>
  import('../features/auth/ResetPasswordScreen').then((m) => ({ default: m.ResetPasswordScreen })),
)
export const VerifyEmailScreen = lazy(() =>
  import('../features/auth/VerifyEmailScreen').then((m) => ({ default: m.VerifyEmailScreen })),
)
export const LinkDeviceScreen = lazy(() =>
  import('../features/auth/LinkDeviceScreen').then((m) => ({ default: m.LinkDeviceScreen })),
)
export const CabinetRoot = lazy(() => import('../app/CabinetRoot').then((m) => ({ default: m.CabinetRoot })))
export const FriendsScreen = lazy(() => import('../features/friends/FriendsScreen').then((m) => ({ default: m.FriendsScreen })))
export const ChannelView = lazy(() => import('../features/messages/ChannelView').then((m) => ({ default: m.ChannelView })))
export const DirectMessageView = lazy(() =>
  import('../features/directMessages/DirectMessageView').then((m) => ({ default: m.DirectMessageView })),
)
export const SettingsScreen = lazy(() =>
  import('../features/settings/SettingsScreen').then((m) => ({ default: m.SettingsScreen })),
)
export const AdminDashboardScreen = lazy(() =>
  import('../features/admin/AdminDashboardScreen').then((m) => ({ default: m.AdminDashboardScreen })),
)
export const KitchenSink = lazy(() => import('../dev/KitchenSink').then((m) => ({ default: m.KitchenSink })))
