import { Eye, EyeOff } from 'lucide-react'
import { forwardRef, useId, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Input } from './Input'
import { Tooltip } from './Tooltip'

export const PasswordInput = forwardRef(function PasswordInput({ className, ...props }, ref) {
  const { t } = useTranslation()
  const [visible, setVisible] = useState(false)
  const labelId = useId()
  const label = visible ? t('common.hidePassword') : t('common.showPassword')

  return (
    <div className="relative">
      <Input ref={ref} type={visible ? 'text' : 'password'} className={`pr-9 ${className ?? ''}`} {...props} />
      <Tooltip content={label}>
        <button
          type="button"
          id={labelId}
          aria-label={label}
          aria-pressed={visible}
          onClick={() => setVisible((current) => !current)}
          className="absolute top-1/2 right-2 -translate-y-1/2 rounded-sm p-0.5 text-fg-muted transition-colors duration-150 hover:text-fg-default focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand"
        >
          {visible ? <EyeOff className="size-4" aria-hidden="true" /> : <Eye className="size-4" aria-hidden="true" />}
        </button>
      </Tooltip>
    </div>
  )
})
