import { useEffect, useRef, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import * as authService from '../../api/authService'
import { Spinner } from '../../components/ui/Spinner'
import { getPendingInvite } from '../servers/pendingInvite'
import { AuthLayout } from './AuthLayout'
import { mapVerifyEmailError } from './authErrors'

const REDIRECT_DELAY_MS = 2500

function loginPathWithInvite() {
  const pendingInvite = getPendingInvite()
  return pendingInvite ? `/login?invite=${encodeURIComponent(pendingInvite)}` : '/login'
}

export function VerifyEmailScreen() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const token = searchParams.get('token') ?? ''
  const [status, setStatus] = useState(token ? 'verifying' : 'error')
  const [errorMessage, setErrorMessage] = useState('')
  const attemptedRef = useRef(false)

  useEffect(() => {
    if (!token || attemptedRef.current) return
    attemptedRef.current = true

    // No cancellation flag here: the ref guard above already ensures this only ever
    // fires once per token (including through React StrictMode's dev double-invoke of
    // effects), so tying the state update to this effect's cleanup would incorrectly
    // drop the result when StrictMode's synthetic cleanup runs before the request settles.
    authService
      .confirmEmail(token)
      .then(() => {
        setStatus('success')
      })
      .catch((error) => {
        setErrorMessage(mapVerifyEmailError(error))
        setStatus('error')
      })
  }, [token])

  useEffect(() => {
    if (status !== 'success') return undefined
    const timer = setTimeout(() => {
      navigate(loginPathWithInvite(), { replace: true })
    }, REDIRECT_DELAY_MS)
    return () => clearTimeout(timer)
  }, [status, navigate])

  if (status === 'verifying') {
    return (
      <AuthLayout title="Verifying your email…" subtitle="Hang tight, this will just take a moment.">
        <div className="flex justify-center py-2">
          <Spinner size="lg" />
        </div>
      </AuthLayout>
    )
  }

  if (status === 'success') {
    return (
      <AuthLayout
        title="Email verified successfully!"
        subtitle="You can now log in to your account."
        footer={
          <Link to={loginPathWithInvite()} className="font-medium text-brand hover:underline">
            Continue to Log In
          </Link>
        }
      />
    )
  }

  return (
    <AuthLayout
      title="This verification link is invalid or has expired."
      subtitle="Log in and use “Resend confirmation email” to get a new link."
      footer={
        <Link to="/login" className="font-medium text-brand hover:underline">
          Back to Log In
        </Link>
      }
    >
      {errorMessage && errorMessage !== 'This verification link is invalid or has expired.' && (
        <p role="alert" className="text-center text-sm text-fg-muted">
          {errorMessage}
        </p>
      )}
    </AuthLayout>
  )
}
