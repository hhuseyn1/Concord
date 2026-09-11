import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '../../components/ui/Button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuTrigger,
} from '../../components/ui/DropdownMenu'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { useAuth } from '../../hooks/useAuth'
import { useUpdateCustomStatusMutation } from './settingsQueries'

const EXPIRY_PRESETS = ['Never', 'ThirtyMinutes', 'OneHour', 'FourHours', 'Today']
const EXPIRY_LABEL_KEY = {
  Never: 'customStatus.dontClear',
  ThirtyMinutes: 'customStatus.thirtyMinutes',
  OneHour: 'customStatus.oneHour',
  FourHours: 'customStatus.fourHours',
  Today: 'customStatus.today',
}

export function CustomStatusModal({ open, onOpenChange }) {
  const { t } = useTranslation()
  const { user } = useAuth()
  const mutation = useUpdateCustomStatusMutation()
  const [emoji, setEmoji] = useState('')
  const [text, setText] = useState('')
  const [expiryPreset, setExpiryPreset] = useState('Never')
  const [prevOpen, setPrevOpen] = useState(open)
  if (open !== prevOpen) {
    setPrevOpen(open)
    if (open) {
      setEmoji(user?.CustomStatusEmoji ?? '')
      setText(user?.CustomStatusText ?? '')
      setExpiryPreset('Never')
    }
  }

  const save = async (nextEmoji, nextText, nextExpiryPreset) => {
    try {
      await mutation.mutateAsync({ Emoji: nextEmoji, Text: nextText, ExpiryPreset: nextExpiryPreset })
      onOpenChange(false)
    } catch (error) {
      toast({ variant: 'danger', title: 'Could not save status', description: error?.message || 'Something went wrong.' })
    }
  }

  const hasExistingStatus = Boolean(user?.CustomStatusText)

  return (
    <Modal
      open={open}
      onOpenChange={onOpenChange}
      title={t('customStatus.title')}
      footer={
        <>
          {hasExistingStatus && (
            <Button variant="ghost" disabled={mutation.isPending} onClick={() => save('', '', 'Never')}>
              {t('customStatus.clear')}
            </Button>
          )}
          <Button variant="secondary" onClick={() => onOpenChange(false)}>
            {t('common.cancel')}
          </Button>
          <Button disabled={mutation.isPending} onClick={() => save(emoji, text, expiryPreset)}>
            {mutation.isPending && <Spinner size="sm" />}
            {t('customStatus.save')}
          </Button>
        </>
      }
    >
      <div className="flex flex-col gap-3">
        <div className="flex gap-2">
          <FormField label="" htmlFor="custom-status-emoji" className="w-16 shrink-0">
            <Input
              id="custom-status-emoji"
              value={emoji}
              onChange={(event) => setEmoji(event.target.value)}
              placeholder={t('customStatus.emojiPlaceholder')}
              aria-label={t('customStatus.emojiLabel')}
              maxLength={16}
              className="text-center"
            />
          </FormField>
          <FormField label="" htmlFor="custom-status-text" className="flex-1">
            <Input
              id="custom-status-text"
              value={text}
              onChange={(event) => setText(event.target.value)}
              placeholder={t('customStatus.placeholder')}
              aria-label={t('customStatus.textLabel')}
              maxLength={128}
            />
          </FormField>
        </div>

        <div className="flex items-center justify-between gap-3">
          <p className="text-sm text-fg-muted">{t('customStatus.clearAfter')}</p>
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="secondary" size="sm">
                {t(EXPIRY_LABEL_KEY[expiryPreset])}
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuRadioGroup value={expiryPreset} onValueChange={setExpiryPreset}>
                {EXPIRY_PRESETS.map((preset) => (
                  <DropdownMenuRadioItem key={preset} value={preset}>
                    {t(EXPIRY_LABEL_KEY[preset])}
                  </DropdownMenuRadioItem>
                ))}
              </DropdownMenuRadioGroup>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>
    </Modal>
  )
}
