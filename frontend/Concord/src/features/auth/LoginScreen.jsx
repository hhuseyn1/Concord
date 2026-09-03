import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import * as authService from '../../api/authService'
import { Button } from '../../components/ui/Button'
import { Checkbox } from '../../components/ui/Checkbox'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { PasswordInput } from '../../components/ui/PasswordInput'
import { Spinner } from '../../components/ui/Spinner'
import { AuthLayout } from './AuthLayout'
import { QrLoginPanel } from './QrLoginPanel'
import { TwoFactorChallenge } from './TwoFactorChallenge'
import { mapLoginError } from './authErrors'

export function LoginScreen() {
  const navigate = useNavigate()
  const location = useLocation()
  const [formError, setFormError] = useState('')
  const [challenge, setChallenge] = useState(null)

  const redirectTo = location.state?.from?.pathname
    ? `${location.state.from.pathname}${location.state.from.search ?? ''}`
    : '/'
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm({ defaultValues: { email: '', password: '', rememberMe: true } })

  const onSubmit = async ({ email, password, rememberMe }) => {
    setFormError('')
    try {
      const result = await authService.login({ Email: email, Password: password, RememberMe: rememberMe })

      if (result?.TwoFactorRequired) {
        setChallenge({ token: result.TwoFactorToken, rememberMe })
        return
      }

      navigate(redirectTo, { replace: true })
    } catch (error) {
      setFormError(mapLoginError(error))
    }
  }

  if (challenge) {
    return (
      <TwoFactorChallenge
        twoFactorToken={challenge.token}
        rememberMe={challenge.rememberMe}
        onCancel={() => setChallenge(null)}
        onSuccess={() => navigate(redirectTo, { replace: true })}
      />
    )
  }

  return (
    <AuthLayout
      title="Welcome back"
      subtitle="We're excited to see you again."
      footer={
        <>
          Need an account?{' '}
          <Link to="/register" className="font-medium text-brand hover:underline">
            Register
          </Link>
        </>
      }
    >
      <form className="flex flex-col gap-4" onSubmit={handleSubmit(onSubmit)} noValidate>
        <FormField label="Email" htmlFor="login-email" error={errors.email?.message} required>
          <Input
            id="login-email"
            type="email"
            autoComplete="email"
            placeholder="you@example.com"
            {...register('email', { required: 'Email is required' })}
          />
        </FormField>

        <FormField label="Password" htmlFor="login-password" error={errors.password?.message} required>
          <PasswordInput
            id="login-password"
            autoComplete="current-password"
            placeholder="••••••••"
            {...register('password', { required: 'Password is required' })}
          />
        </FormField>

        <div className="flex items-center justify-between text-sm">
          <label htmlFor="login-remember-me" className="flex items-center gap-2 text-fg-muted">
            <Checkbox id="login-remember-me" {...register('rememberMe')} />
            Remember me
          </label>
          <Link to="/forgot-password" className="font-medium text-brand hover:underline">
            Forgot password?
          </Link>
        </div>

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
          {isSubmitting ? 'Logging in…' : 'Log In'}
        </Button>
      </form>

      <div className="mt-6 border-t border-border-subtle pt-6">
        <QrLoginPanel onAuthenticated={() => navigate(redirectTo, { replace: true })} />
      </div>
    </AuthLayout>
  )
}
