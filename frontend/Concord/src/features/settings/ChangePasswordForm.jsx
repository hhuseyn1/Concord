import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { useTranslation } from 'react-i18next'
import { Button } from '../../components/ui/Button'
import { FormField } from '../../components/ui/FormField'
import { PasswordInput } from '../../components/ui/PasswordInput'
import { Spinner } from '../../components/ui/Spinner'
import { mapChangePasswordError } from './settingsErrors'
import { useChangePasswordMutation } from './settingsQueries'

export function ChangePasswordForm() {
  const { t } = useTranslation()
  const [formError, setFormError] = useState('')
  const [success, setSuccess] = useState(false)
  const changePasswordMutation = useChangePasswordMutation()
  const {
    register,
    handleSubmit,
    watch,
    reset,
    formState: { errors, isSubmitting },
  } = useForm({ defaultValues: { currentPassword: '', newPassword: '', confirmNewPassword: '' } })

  const newPassword = watch('newPassword')

  const onSubmit = async ({ currentPassword, newPassword: nextPassword }) => {
    setFormError('')
    setSuccess(false)
    try {
      await changePasswordMutation.mutateAsync({ CurrentPassword: currentPassword, NewPassword: nextPassword })
      setSuccess(true)
      reset()
    } catch (error) {
      setFormError(mapChangePasswordError(error))
    }
  }

  return (
    <form className="flex max-w-md flex-col gap-4" onSubmit={handleSubmit(onSubmit)} noValidate>
      <FormField label={t('settings.currentPassword')} htmlFor="change-password-current" error={errors.currentPassword?.message} required>
        <PasswordInput
          id="change-password-current"
          autoComplete="current-password"
          {...register('currentPassword', { required: 'Current password is required' })}
        />
      </FormField>

      <FormField
        label={t('settings.newPassword')}
        htmlFor="change-password-new"
        error={errors.newPassword?.message}
        hint={!errors.newPassword ? 'At least 8 characters.' : undefined}
        required
      >
        <PasswordInput
          id="change-password-new"
          autoComplete="new-password"
          {...register('newPassword', {
            required: 'New password is required',
            minLength: { value: 8, message: 'Password must be at least 8 characters' },
          })}
        />
      </FormField>

      <FormField
        label={t('settings.confirmNewPassword')}
        htmlFor="change-password-confirm"
        error={errors.confirmNewPassword?.message}
        required
      >
        <PasswordInput
          id="change-password-confirm"
          autoComplete="new-password"
          {...register('confirmNewPassword', {
            required: 'Please confirm your new password',
            validate: (value) => value === newPassword || "Passwords don't match",
          })}
        />
      </FormField>

      {formError && (
        <p role="alert" className="rounded-md border border-danger/40 bg-danger-bg px-3 py-2 text-sm text-danger">
          {formError}
        </p>
      )}

      {success && (
        <p role="status" className="rounded-md border border-success/40 bg-success-bg px-3 py-2 text-sm text-success">
          {t('settings.changePasswordSuccess')}
        </p>
      )}

      <Button
        type="submit"
        size="lg"
        disabled={isSubmitting || changePasswordMutation.isPending}
        className="self-start"
      >
        {isSubmitting && <Spinner size="sm" />}
        {isSubmitting ? t('common.saving') : t('settings.changePasswordAction')}
      </Button>
    </form>
  )
}
