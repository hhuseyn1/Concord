import { Phone, PhoneOff, Video } from 'lucide-react'
import { useEffect } from 'react'
import { useTranslation } from 'react-i18next'
import { Avatar } from '../../components/ui/Avatar'
import { Button } from '../../components/ui/Button'
import { Modal } from '../../components/ui/Modal'
import { useAuth } from '../../hooks/useAuth'
import { startRingtone, stopRingtone } from './ringtone'

export function IncomingCallModal({ incomingCall, onAccept, onDecline }) {
  const { t } = useTranslation()
  const { user } = useAuth()

  useEffect(() => {
    if (incomingCall && user?.NotificationsSoundEnabled !== false) {
      startRingtone()
    }
    return () => stopRingtone()
  }, [incomingCall, user?.NotificationsSoundEnabled])

  if (!incomingCall) return null

  const isVideo = incomingCall.type === 'Video'
  const TypeIcon = isVideo ? Video : Phone

  return (
    <Modal
      open
      onOpenChange={(open) => {
        if (!open) onDecline()
      }}
      title={t(isVideo ? 'calls.incomingVideoCall' : 'calls.incomingVoiceCall')}
      size="sm"
    >
      <div className="flex flex-col items-center gap-4 py-2">
        <Avatar src={incomingCall.callerAvatarUrl} name={incomingCall.callerDisplayName} size="xl" />
        <div className="flex items-center gap-2 text-center">
          <TypeIcon className="size-4 shrink-0 text-fg-muted" aria-hidden="true" />
          <p className="text-base font-semibold text-fg-default">{incomingCall.callerDisplayName}</p>
        </div>

        <div className="flex w-full gap-3">
          <Button variant="danger" className="flex-1" onClick={onDecline}>
            <PhoneOff className="size-4" aria-hidden="true" />
            {t('friends.decline')}
          </Button>
          <Button className="flex-1" onClick={onAccept}>
            <Phone className="size-4" aria-hidden="true" />
            {t('friends.accept')}
          </Button>
        </div>
      </div>
    </Modal>
  )
}
