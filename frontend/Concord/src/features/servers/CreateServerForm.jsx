import { ImagePlus } from 'lucide-react'
import { useRef, useState } from 'react'
import * as filesService from '../../api/filesService'
import { Avatar } from '../../components/ui/Avatar'
import { Button } from '../../components/ui/Button'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { mapCreateServerError, mapServerIconUploadError } from './serversErrors'
import { useCreateServerMutation } from './serversQueries'

export function CreateServerForm({ onDone }) {
  const [name, setName] = useState('')
  const [nameError, setNameError] = useState('')
  const [iconFile, setIconFile] = useState(null)
  const [iconPreview, setIconPreview] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const fileInputRef = useRef(null)
  const createMutation = useCreateServerMutation()

  const handleFileChange = (event) => {
    const file = event.target.files?.[0]
    if (!file) return
    setIconFile(file)
    setIconPreview(URL.createObjectURL(file))
  }

  const handleSubmit = async (event) => {
    event.preventDefault()
    const trimmed = name.trim()
    if (!trimmed) {
      setNameError('Server name is required.')
      return
    }
    setNameError('')
    setSubmitting(true)
    try {
      let iconUrl = null
      if (iconFile) {
        try {
          const uploaded = await filesService.uploadServerIcon(iconFile)
          iconUrl = uploaded.Url
        } catch (uploadError) {
          toast({
            variant: 'danger',
            title: 'Could not upload icon',
            description: mapServerIconUploadError(uploadError),
          })
          setSubmitting(false)
          return
        }
      }
      const server = await createMutation.mutateAsync({ Name: trimmed, IconUrl: iconUrl })
      toast({ variant: 'success', title: 'Server created', description: `"${server.Name}" is ready.` })
      onDone?.()
    } catch (error) {
      if (error?.status === 400) {
        setNameError(mapCreateServerError(error))
      } else {
        toast({ variant: 'danger', title: 'Could not create server', description: mapCreateServerError(error) })
      }
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <form className="flex flex-col gap-4 pt-1" onSubmit={handleSubmit} noValidate>
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={() => fileInputRef.current?.click()}
          className="group flex size-16 shrink-0 items-center justify-center overflow-hidden rounded-full border border-dashed border-border-default bg-surface-sidebar transition-colors duration-150 hover:border-brand"
          aria-label="Upload a server icon"
        >
          {iconPreview ? (
            <Avatar src={iconPreview} name={name || 'Server'} size="xl" className="size-full" />
          ) : (
            <ImagePlus
              className="size-5 text-fg-muted transition-colors duration-150 group-hover:text-brand"
              aria-hidden="true"
            />
          )}
        </button>
        <div className="flex flex-col gap-1">
          <p className="text-sm font-medium text-fg-default">Server icon</p>
          <p className="text-xs text-fg-muted">Optional. PNG, JPEG, WEBP or GIF, up to 5 MB.</p>
        </div>
        <input
          ref={fileInputRef}
          type="file"
          accept="image/png,image/jpeg,image/webp,image/gif"
          className="hidden"
          onChange={handleFileChange}
        />
      </div>

      <FormField label="Server name" htmlFor="create-server-name" error={nameError} required>
        <Input
          id="create-server-name"
          value={name}
          onChange={(event) => setName(event.target.value)}
          placeholder="My Server"
          autoFocus
        />
      </FormField>

      <Button type="submit" size="lg" disabled={submitting}>
        {submitting && <Spinner size="sm" />}
        {submitting ? 'Creating…' : 'Create Server'}
      </Button>
    </form>
  )
}
