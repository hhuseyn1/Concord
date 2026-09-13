import { CheckCircle2, XCircle } from 'lucide-react'
import { forwardRef, useEffect, useRef, useState } from 'react'
import { useForm } from 'react-hook-form'
import { Link, useSearchParams } from 'react-router-dom'
import * as authService from '../../api/authService'
import { Button } from '../../components/ui/Button'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { PasswordInput } from '../../components/ui/PasswordInput'
import { Spinner } from '../../components/ui/Spinner'
import { useCapturePendingInviteFromUrl } from '../servers/pendingInvite'
import { AuthLayout } from './AuthLayout'
import { mapRegisterError } from './authErrors'

const USERNAME_PATTERN = /^[a-zA-Z0-9_]{1,32}$/
const USERNAME_CHECK_DEBOUNCE_MS = 350

// Mirrors PasswordInput's mechanical shape: a relatively-positioned wrapper around `Input` with
// an absolutely-positioned status slot on the right, swapped here for a spinner/check/cross icon
// instead of the show/hide-password toggle.
const UsernameInput = forwardRef(function UsernameInput({ className, status, ...props }, ref) {
  return (
    <div className="relative">
      <Input ref={ref} className={`pr-9 ${className ?? ''}`} {...props} />
      {status === 'checking' && (
        <span className="absolute top-1/2 right-2 -translate-y-1/2">
          <Spinner size="sm" />
        </span>
      )}
      {status === 'available' && (
        <CheckCircle2
          className="absolute top-1/2 right-2 size-4 -translate-y-1/2 text-success"
          aria-label="Username is available"
          role="img"
        />
      )}
      {status === 'taken' && (
        <XCircle
          className="absolute top-1/2 right-2 size-4 -translate-y-1/2 text-danger"
          aria-label="Username is taken"
          role="img"
        />
      )}
    </div>
  )
})

export function RegisterScreen() {
  const [searchParams] = useSearchParams()
  useCapturePendingInviteFromUrl(searchParams)

  const [formError, setFormError] = useState('')
  const [registered, setRegistered] = useState(false)
  const [registeredEmail, setRegisteredEmail] = useState('')
  const [resendState, setResendState] = useState('idle')
  const {
    register,
    handleSubmit,
    watch,
    formState: { errors, isSubmitting },
  } = useForm({ defaultValues: { name: '', surname: '', username: '', email: '', password: '' } })

  const username = watch('username')
  const [debouncedUsername, setDebouncedUsername] = useState('')
  const [usernameAvailability, setUsernameAvailability] = useState('idle') // idle | checking | available | taken
  const lastSubmittedUsernameRef = useRef('')

  useEffect(() => {
    const handle = setTimeout(() => setDebouncedUsername((username ?? '').trim()), USERNAME_CHECK_DEBOUNCE_MS)
    return () => clearTimeout(handle)
  }, [username])

  useEffect(() => {
    const isFormatValid = USERNAME_PATTERN.test(debouncedUsername)
    if (!debouncedUsername || !isFormatValid || debouncedUsername === lastSubmittedUsernameRef.current) {
      setUsernameAvailability('idle')
      return undefined
    }

    let cancelled = false
    setUsernameAvailability('checking')

    authService
      .checkUsernameAvailable(debouncedUsername)
      .then((available) => {
        if (cancelled) return
        setUsernameAvailability(available ? 'available' : 'taken')
      })
      .catch(() => {
        if (cancelled) return
        setUsernameAvailability('idle')
      })

    return () => {
      cancelled = true
    }
  }, [debouncedUsername])

  const onSubmit = async ({ name, surname, username, email, password }) => {
    setFormError('')
    lastSubmittedUsernameRef.current = username
    try {
      await authService.register({
        Name: name,
        Surname: surname,
        Username: username,
        Email: email,
        Password: password,
      })
      setRegisteredEmail(email)
      setRegistered(true)
    } catch (error) {
      setFormError(mapRegisterError(error))
    }
  }

  const handleResend = async () => {
    setResendState('pending')
    try {
      await authService.resendVerificationEmail(registeredEmail)
      setResendState('sent')
    } catch {
      setResendState('idle')
    }
  }

  if (registered) {
    return (
      <AuthLayout
        title="Check your email"
        subtitle={`We've sent a confirmation link to ${registeredEmail}. Click it to activate your account, then log in.`}
        footer={
          <Link to="/login" className="font-medium text-brand hover:underline">
            Back to Log In
          </Link>
        }
      >
        <div className="flex flex-col items-center gap-2">
          <Button
            type="button"
            variant="secondary"
            disabled={resendState === 'pending'}
            onClick={handleResend}
          >
            {resendState === 'pending' && <Spinner size="sm" />}
            {resendState === 'sent' ? 'Sent!' : resendState === 'pending' ? 'Sending…' : 'Resend email'}
          </Button>
        </div>
      </AuthLayout>
    )
  }

  return (
    <AuthLayout
      title="Create an account"
      subtitle="Join Concord and start chatting."
      footer={
        <>
          Already have an account?{' '}
          <Link to="/login" className="font-medium text-brand hover:underline">
            Log In
          </Link>
        </>
      }
    >
      <form className="flex flex-col gap-4" onSubmit={handleSubmit(onSubmit)} noValidate>
        <div className="grid grid-cols-2 gap-3">
          <FormField label="Name" htmlFor="register-name" error={errors.name?.message} required>
            <Input
              id="register-name"
              autoComplete="given-name"
              placeholder="Jane"
              {...register('name', { required: 'Name is required' })}
            />
          </FormField>

          <FormField label="Surname" htmlFor="register-surname" error={errors.surname?.message} required>
            <Input
              id="register-surname"
              autoComplete="family-name"
              placeholder="Doe"
              {...register('surname', { required: 'Surname is required' })}
            />
          </FormField>
        </div>

        <FormField
          label="Username"
          htmlFor="register-username"
          error={errors.username?.message}
          hint={!errors.username ? 'Letters, numbers, and underscores only - up to 32 characters. This is how friends find you.' : undefined}
          required
        >
          <UsernameInput
            id="register-username"
            autoComplete="username"
            placeholder="janedoe"
            status={usernameAvailability}
            invalid={usernameAvailability === 'taken' || undefined}
            {...register('username', {
              required: 'Username is required',
              pattern: {
                value: USERNAME_PATTERN,
                message: 'Only letters, numbers, and underscores - up to 32 characters.',
              },
            })}
          />
        </FormField>

        <FormField label="Email" htmlFor="register-email" error={errors.email?.message} required>
          <Input
            id="register-email"
            type="email"
            autoComplete="email"
            placeholder="you@example.com"
            {...register('email', {
              required: 'Email is required',
              validate: (value) => value.includes('@') || 'Enter a valid email address',
            })}
          />
        </FormField>

        <FormField
          label="Password"
          htmlFor="register-password"
          error={errors.password?.message}
          hint={!errors.password ? 'At least 8 characters.' : undefined}
          required
        >
          <PasswordInput
            id="register-password"
            autoComplete="new-password"
            placeholder="••••••••"
            {...register('password', {
              required: 'Password is required',
              minLength: { value: 8, message: 'Password must be at least 8 characters' },
            })}
          />
        </FormField>

        {formError && (
          <p
            role="alert"
            className="rounded-md border border-danger/40 bg-danger-bg px-3 py-2 text-sm text-danger"
          >
            {formError}
          </p>
        )}

        <Button type="submit" size="lg" disabled={isSubmitting} className="mt-2">
          {isSubmitting && <Spinner size="sm" />}
          {isSubmitting ? 'Creating account…' : 'Create Account'}
        </Button>
      </form>
    </AuthLayout>
  )
}
