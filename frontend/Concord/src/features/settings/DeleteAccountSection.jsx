import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useNavigate } from 'react-router-dom'
import * as tokenStorage from '../../api/tokenStorage'
import { Button } from '../../components/ui/Button'
import { FormField } from '../../components/ui/FormField'
import { Modal } from '../../components/ui/Modal'
import { PasswordInput } from '../../components/ui/PasswordInput'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { mapDeleteAccountError } from './settingsErrors'
import { useDeleteAccountMutation } from './settingsQueries'

export function DeleteAccountSection() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const deleteMutation = useDeleteAccountMutation()
  const [open, setOpen] = useState(false)
  const [password, setPassword] = useState('')
  const [formError, setFormError] = useState('')

  const handleClose = (nextOpen) => {
    if (!nextOpen && !deleteMutation.isPending) {
      setPassword('')
      setFormError('')
    }
    setOpen(nextOpen)
  }

  const handleDelete = async () => {
    setFormError('')
    try {
      await deleteMutation.mutateAsync({ Password: password })
      // Same underlying primitive the sign-out flow uses to clear local auth state.
      tokenStorage.clearTokens()
      toast({
        variant: 'success',
        title: t('settings.deleteAccountSuccessToastTitle'),
        description: t('settings.deleteAccountSuccessToastDescription'),
      })
      setOpen(false)
      setPassword('')
      navigate('/login', { replace: true })
    } catch (error) {
      setFormError(mapDeleteAccountError(error))
    }
  }

  return (
    <section className="flex max-w-md flex-col gap-3 rounded-md border border-danger/40 bg-danger-bg p-4">
      <div>
        <h2 className="text-sm font-semibold text-danger">{t('settings.dangerZone')}</h2>
        <p className="mt-1 text-xs text-fg-muted">{t('settings.deleteAccountDescription')}</p>
      </div>
      <div>
        <Button variant="danger" size="sm" onClick={() => setOpen(true)}>
          {t('settings.deleteAccount')}
        </Button>
      </div>

      <Modal
        open={open}
        onOpenChange={handleClose}
        title={t('settings.deleteAccountTitle')}
        description={t('settings.deleteAccountConsequences')}
        footer={
          <>
            <Button variant="ghost" onClick={() => handleClose(false)} disabled={deleteMutation.isPending}>
              {t('common.cancel')}
            </Button>
            <Button
              variant="danger"
              onClick={handleDelete}
              disabled={deleteMutation.isPending || password.length === 0}
            >
              {deleteMutation.isPending && <Spinner size="sm" />}
              {t('settings.deleteAccountAction')}
            </Button>
          </>
        }
      >
        <div className="flex flex-col gap-3">
          <FormField
            label={t('settings.deleteAccountPasswordLabel')}
            htmlFor="delete-account-password"
            error={formError}
            required
          >
            <PasswordInput
              id="delete-account-password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              autoComplete="current-password"
              autoFocus
            />
          </FormField>
        </div>
      </Modal>
    </section>
  )
}
