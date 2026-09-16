import { QueryClientProvider } from '@tanstack/react-query'
import { I18nextProvider } from 'react-i18next'
import { RouterProvider } from 'react-router-dom'
import i18n from '../i18n'
import { ToastProvider } from '../components/ui/Toast'
import { queryClient } from '../lib/queryClient'
import { router } from '../lib/router'
import { AuthProvider } from './AuthProvider'
import { ErrorBoundary } from './ErrorBoundary'

function App() {
  return (
    <I18nextProvider i18n={i18n}>
      <QueryClientProvider client={queryClient}>
        <ToastProvider>
          <AuthProvider>
            <ErrorBoundary>
              <RouterProvider router={router} />
            </ErrorBoundary>
          </AuthProvider>
        </ToastProvider>
      </QueryClientProvider>
    </I18nextProvider>
  )
}

export default App
