import { ImagePlus } from 'lucide-react'
import { useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import * as filesService from '../../api/filesService'
import { Avatar } from '../../components/ui/Avatar'
import { Button } from '../../components/ui/Button'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { mapServerIconUploadError, mapUpdateServerError } from './serversErrors'
import { useUpdateServerMutation } from './serversQueries'

export function EditServerModal({ server, open, onOpenChange }) {
  const { t } = useTranslation()
  const [name, setName] = useState(server?.Name || '')
  const [nameError, setNameError] = useState('')
  const [iconFile, setIconFile] = useState(null)
  const [iconPreview, setIconPreview] = useState(server?.IconUrl || '')
  const [submitting, setSubmitting] = useState(false)
  const fileInputRef = useRef(null)
  const updateMutation = useUpdateServerMutation(server?.Id)

  const [prevOpen, setPrevOpen] = useState(open)
  if (open !== prevOpen) {
    setPrevOpen(open)
    if (open) {
      setName(server?.Name || '')
      setIconPreview(server?.IconUrl || '')
      setIconFile(null)
      setNameError('')
    }
  }

  useEffect(() => {
    return () => {
      if (iconPreview && iconPreview.startsWith('blob:')) URL.revokeObjectURL(iconPreview)
    }
  }, [iconPreview])

  const handleFileChange = (event) => {
    const file = event.target.files?.[0]
    if (!file) return
    setIconFile(file)
    setIconPreview(URL.createObjectURL(file))
  }

  const handleClose = (next) => {
    onOpenChange(next)
  }

  const handleSubmit = async (event) => {
    event.preventDefault()
    const trimmed = name.trim()
    if (!trimmed) {
      setNameError(t('servers.nameRequired'))
      return
    }
    setNameError('')
    setSubmitting(true)
    try {
      let iconUrl = server?.IconUrl ?? null
      if (iconFile) {
        try {
          const uploaded = await filesService.uploadServerIcon(iconFile)
          iconUrl = uploaded.Url
        } catch (uploadError) {
          toast({ variant: 'danger', title: t('servers.iconUploadFailed'), description: mapServerIconUploadError(uploadError) })
          setSubmitting(false)
          return
        }
      }
      await updateMutation.mutateAsync({ Name: trimmed, IconUrl: iconUrl })
      toast({ variant: 'success', title: t('servers.updated'), description: trimmed })
      handleClose(false)
    } catch (error) {
      if (error?.status === 400) {
        setNameError(mapUpdateServerError(error))
      } else {
        toast({ variant: 'danger', title: t('servers.updateFailed'), description: mapUpdateServerError(error) })
      }
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <Modal open={open} onOpenChange={handleClose} title={t('servers.editServer')} description={t('servers.editServerDescription')}>
      <form className="flex flex-col gap-4 pt-1" onSubmit={handleSubmit} noValidate>
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => fileInputRef.current?.click()}
            className="group flex size-16 shrink-0 items-center justify-center overflow-hidden rounded-full border border-dashed border-border-default bg-surface-sidebar transition-colors duration-150 hover:border-brand"
            aria-label={t('servers.uploadIcon')}
          >
            {iconPreview ? (
              <Avatar src={iconPreview} name={name || 'Server'} size="xl" className="size-full" />
            ) : (
              <ImagePlus className="size-5 text-fg-muted transition-colors duration-150 group-hover:text-brand" aria-hidden="true" />
            )}
          </button>
          <div className="flex flex-col gap-1">
            <p className="text-sm font-medium text-fg-default">{t('servers.serverIcon')}</p>
            <p className="text-xs text-fg-muted">{t('servers.iconHint')}</p>
          </div>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/png,image/jpeg,image/webp,image/gif"
            className="hidden"
            onChange={handleFileChange}
          />
        </div>

        <FormField label={t('servers.serverName')} htmlFor="edit-server-name" error={nameError} required>
          <Input id="edit-server-name" value={name} onChange={(event) => setName(event.target.value)} autoFocus />
        </FormField>

        <div className="flex justify-end gap-2 pt-1">
          <Button type="button" variant="ghost" onClick={() => handleClose(false)}>
            {t('common.cancel')}
          </Button>
          <Button type="submit" disabled={submitting}>
            {submitting && <Spinner size="sm" />}
            {t('common.save')}
          </Button>
        </div>
      </form>
    </Modal>
  )
}
