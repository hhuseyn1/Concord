import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import * as authService from '../../api/authService'
import { Button } from '../../components/ui/Button'
import { FormField } from '../../components/ui/FormField'
import { PasswordInput } from '../../components/ui/PasswordInput'
import { Spinner } from '../../components/ui/Spinner'
import { AuthLayout } from './AuthLayout'
import { mapResetPasswordError } from './authErrors'

export function ResetPasswordScreen() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const token = searchParams.get('token') ?? ''
  const [formError, setFormError] = useState('')
  const {
    register,
    handleSubmit,
    watch,
    formState: { errors, isSubmitting },
  } = useForm({ defaultValues: { password: '', confirmPassword: '' } })

  const onSubmit = async ({ password }) => {
    setFormError('')
    try {
      await authService.confirmPasswordReset(token, password)
      navigate('/login', { replace: true })
    } catch (error) {
      setFormError(mapResetPasswordError(error))
    }
  }

  if (!token) {
    return (
      <AuthLayout
        title="Invalid reset link"
        subtitle="This password reset link is missing its token."
        footer={
          <Link to="/forgot-password" className="font-medium text-brand hover:underline">
            Request a new link
          </Link>
        }
      />
    )
  }

  return (
    <AuthLayout title="Reset your password" subtitle="Choose a new password for your account.">
      <form className="flex flex-col gap-4" onSubmit={handleSubmit(onSubmit)} noValidate>
        <FormField
          label="New password"
          htmlFor="reset-password-password"
          error={errors.password?.message}
          hint={!errors.password ? 'At least 8 characters.' : undefined}
          required
        >
          <PasswordInput
            id="reset-password-password"
            autoComplete="new-password"
            placeholder="••••••••"
            {...register('password', {
              required: 'Password is required',
              minLength: { value: 8, message: 'Password must be at least 8 characters' },
            })}
          />
        </FormField>

        <FormField
          label="Confirm new password"
          htmlFor="reset-password-confirm-password"
          error={errors.confirmPassword?.message}
          required
        >
          <PasswordInput
            id="reset-password-confirm-password"
            autoComplete="new-password"
            placeholder="••••••••"
            {...register('confirmPassword', {
              required: 'Please confirm your password',
              validate: (value) => value === watch('password') || 'Passwords do not match',
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
          {isSubmitting ? 'Resetting…' : 'Reset password'}
        </Button>
      </form>
    </AuthLayout>
  )
}
