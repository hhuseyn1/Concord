import { QueryClientProvider } from '@tanstack/react-query'
import { I18nextProvider } from 'react-i18next'
import { RouterProvider } from 'react-router-dom'
import i18n from '../i18n'
import { ToastProvider } from '../components/ui/Toast'
import { queryClient } from '../lib/queryClient'
import { router } from '../lib/router'
import { AuthProvider } from './AuthProvider'
import { DirectMessagesProvider } from './DirectMessagesProvider'
import { ErrorBoundary } from './ErrorBoundary'
import { NotificationsProvider } from './NotificationsProvider'
import { PresenceProvider } from './PresenceProvider'
import { VoiceCallProvider } from './VoiceCallProvider'

function App() {
  return (
    <I18nextProvider i18n={i18n}>
      <QueryClientProvider client={queryClient}>
        <ToastProvider>
          <AuthProvider>
            <PresenceProvider>
              <NotificationsProvider>
                <DirectMessagesProvider>
                  <VoiceCallProvider>
                    <ErrorBoundary>
                      <RouterProvider router={router} />
                    </ErrorBoundary>
                  </VoiceCallProvider>
                </DirectMessagesProvider>
              </NotificationsProvider>
            </PresenceProvider>
          </AuthProvider>
        </ToastProvider>
      </QueryClientProvider>
    </I18nextProvider>
  )
}

export default App
