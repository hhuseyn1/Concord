import { ImagePlus } from 'lucide-react'
import { useEffect, useRef, useState } from 'react'
import { useForm } from 'react-hook-form'
import { useTranslation } from 'react-i18next'
import * as filesService from '../../api/filesService'
import { Avatar } from '../../components/ui/Avatar'
import { Button } from '../../components/ui/Button'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { useAuth } from '../../hooks/useAuth'
import { mapAvatarUploadError, mapUpdateProfileError } from './settingsErrors'
import { useUpdateProfileMutation } from './settingsQueries'

const USERNAME_PATTERN = /^[a-zA-Z0-9_]{1,32}$/

export function AccountSettingsForm() {
  const { t } = useTranslation()
  const { user } = useAuth()
  const [avatarFile, setAvatarFile] = useState(null)
  const [avatarPreview, setAvatarPreview] = useState('')
  const [formError, setFormError] = useState('')
  const fileInputRef = useRef(null)
  const updateMutation = useUpdateProfileMutation()

  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting, isDirty },
  } = useForm({
    values: user
      ? { name: user.Name ?? '', surname: user.Surname ?? '', username: user.Username ?? '' }
      : undefined,
  })

  useEffect(() => {
    return () => {
      if (avatarPreview) URL.revokeObjectURL(avatarPreview)
    }
  }, [avatarPreview])

  const handleFileChange = (event) => {
    const file = event.target.files?.[0]
    if (!file) return
    setAvatarFile(file)
    setAvatarPreview(URL.createObjectURL(file))
  }

  const onSubmit = async ({ name, surname, username }) => {
    setFormError('')

    let avatarUrl = user?.AvatarUrl ?? null
    if (avatarFile) {
      try {
        const uploaded = await filesService.uploadAvatar(avatarFile)
        avatarUrl = uploaded.Url
      } catch (uploadError) {
        toast({
          variant: 'danger',
          title: 'Could not upload avatar',
          description: mapAvatarUploadError(uploadError),
        })
        return
      }
    }

    try {
      await updateMutation.mutateAsync({ Name: name, Surname: surname, Username: username, AvatarUrl: avatarUrl })
      toast({ variant: 'success', description: 'Profile updated.' })
      setAvatarFile(null)
      setAvatarPreview('')
    } catch (error) {
      if (error?.status === 409) {
        setError('username', { message: mapUpdateProfileError(error) })
      } else {
        setFormError(mapUpdateProfileError(error))
      }
    }
  }

  const displayAvatar = avatarPreview || user?.AvatarUrl || undefined

  return (
    <form className="flex max-w-md flex-col gap-4" onSubmit={handleSubmit(onSubmit)} noValidate>
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={() => fileInputRef.current?.click()}
          className="group relative flex size-16 shrink-0 items-center justify-center overflow-hidden rounded-full border border-dashed border-border-default bg-surface-sidebar transition-colors duration-150 hover:border-brand"
          aria-label="Upload a new avatar"
        >
          <Avatar src={displayAvatar} name={user?.Username ?? user?.Name ?? undefined} size="xl" className="size-full" />
          <span className="absolute inset-0 flex items-center justify-center bg-black/40 opacity-0 transition-opacity duration-150 group-hover:opacity-100">
            <ImagePlus className="size-5 text-white" aria-hidden="true" />
          </span>
        </button>
        <div className="flex flex-col gap-1">
          <p className="text-sm font-medium text-fg-default">Avatar</p>
          <p className="text-xs text-fg-muted">PNG, JPEG, WEBP or GIF, up to 5 MB.</p>
        </div>
        <input
          ref={fileInputRef}
          type="file"
          accept="image/png,image/jpeg,image/webp,image/gif"
          className="hidden"
          onChange={handleFileChange}
        />
      </div>

      <div className="grid grid-cols-2 gap-3">
        <FormField label="Name" htmlFor="settings-name" error={errors.name?.message} required>
          <Input
            id="settings-name"
            autoComplete="given-name"
            {...register('name', { required: 'Name is required' })}
          />
        </FormField>

        <FormField label="Surname" htmlFor="settings-surname" error={errors.surname?.message} required>
          <Input
            id="settings-surname"
            autoComplete="family-name"
            {...register('surname', { required: 'Surname is required' })}
          />
        </FormField>
      </div>

      <FormField
        label="Username"
        htmlFor="settings-username"
        error={errors.username?.message}
        hint={!errors.username ? 'Letters, numbers, and underscores only — up to 32 characters.' : undefined}
        required
      >
        <Input
          id="settings-username"
          autoComplete="username"
          {...register('username', {
            required: 'Username is required',
            pattern: {
              value: USERNAME_PATTERN,
              message: 'Only letters, numbers, and underscores — up to 32 characters.',
            },
          })}
        />
      </FormField>

      <FormField label={t('settings.email')} htmlFor="settings-email" hint={t('settings.emailReadOnlyHint')}>
        <Input id="settings-email" value={user?.Email ?? ''} disabled readOnly />
      </FormField>

      {formError && (
        <p role="alert" className="rounded-md border border-danger/40 bg-danger-bg px-3 py-2 text-sm text-danger">
          {formError}
        </p>
      )}

      <Button type="submit" size="lg" disabled={isSubmitting || (!isDirty && !avatarFile)} className="self-start">
        {isSubmitting && <Spinner size="sm" />}
        {isSubmitting ? 'Saving…' : 'Save Changes'}
      </Button>
    </form>
  )
}
