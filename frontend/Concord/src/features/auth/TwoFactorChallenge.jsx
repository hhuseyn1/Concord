import { useState } from 'react'
import { useForm } from 'react-hook-form'
import * as authService from '../../api/authService'
import { Button } from '../../components/ui/Button'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { Spinner } from '../../components/ui/Spinner'
import { AuthLayout } from './AuthLayout'
import { mapTwoFactorLoginError } from './authErrors'

export function TwoFactorChallenge({ twoFactorToken, rememberMe, onCancel, onSuccess }) {
  const [formError, setFormError] = useState('')
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm({ defaultValues: { code: '' } })

  const onSubmit = async ({ code }) => {
    setFormError('')
    try {
      await authService.completeTwoFactorLogin({ TwoFactorToken: twoFactorToken, Code: code, rememberMe })
      onSuccess()
    } catch (error) {
      setFormError(mapTwoFactorLoginError(error))
    }
  }

  return (
    <AuthLayout
      title="Two-factor authentication"
      subtitle="Enter the code from your authenticator app, or one of your recovery codes."
      footer={
        <button type="button" onClick={onCancel} className="font-medium text-brand hover:underline">
          Back to sign in
        </button>
      }
    >
      <form className="flex flex-col gap-4" onSubmit={handleSubmit(onSubmit)} noValidate>
        <FormField label="Authentication code" htmlFor="login-2fa-code" error={errors.code?.message} required>
          <Input
            id="login-2fa-code"
            autoComplete="one-time-code"
            inputMode="text"
            autoFocus
            placeholder="123456 or ABCD-EFGH"
            {...register('code', { required: 'Enter your authentication code' })}
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
          {isSubmitting ? 'Verifying…' : 'Verify'}
        </Button>
      </form>
    </AuthLayout>
  )
}
