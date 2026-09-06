import { useState } from 'react'
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
    formState: { errors, isSubmitting },
  } = useForm({ defaultValues: { name: '', surname: '', email: '', password: '' } })

  const onSubmit = async ({ name, surname, email, password }) => {
    setFormError('')
    try {
      await authService.register({ Name: name, Surname: surname, Email: email, Password: password })
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
