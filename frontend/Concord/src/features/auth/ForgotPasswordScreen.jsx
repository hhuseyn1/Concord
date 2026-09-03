import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { Link } from 'react-router-dom'
import * as authService from '../../api/authService'
import { Button } from '../../components/ui/Button'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { Spinner } from '../../components/ui/Spinner'
import { AuthLayout } from './AuthLayout'
import { mapForgotPasswordError } from './authErrors'

export function ForgotPasswordScreen() {
  const [formError, setFormError] = useState('')
  const [submitted, setSubmitted] = useState(false)
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm({ defaultValues: { email: '' } })

  const onSubmit = async ({ email }) => {
    setFormError('')
    try {
      await authService.requestPasswordReset(email)
      setSubmitted(true)
    } catch (error) {
      setFormError(mapForgotPasswordError(error))
    }
  }

  if (submitted) {
    return (
      <AuthLayout
        title="Check your email"
        subtitle="If an account exists for that email, we've sent a link to reset your password."
        footer={
          <Link to="/login" className="font-medium text-brand hover:underline">
            Back to Log In
          </Link>
        }
      />
    )
  }

  return (
    <AuthLayout
      title="Forgot password?"
      subtitle="Enter your email and we'll send you a reset link."
      footer={
        <Link to="/login" className="font-medium text-brand hover:underline">
          Back to Log In
        </Link>
      }
    >
      <form className="flex flex-col gap-4" onSubmit={handleSubmit(onSubmit)} noValidate>
        <FormField label="Email" htmlFor="forgot-password-email" error={errors.email?.message} required>
          <Input
            id="forgot-password-email"
            type="email"
            autoComplete="email"
            placeholder="you@example.com"
            {...register('email', { required: 'Email is required' })}
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
          {isSubmitting ? 'Sending…' : 'Send reset link'}
        </Button>
      </form>
    </AuthLayout>
  )
}
