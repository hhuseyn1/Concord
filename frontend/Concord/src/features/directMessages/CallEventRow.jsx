import { Phone, PhoneMissed, Video } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Tooltip } from '../../components/ui/Tooltip'
import { cn } from '../../lib/cn'
import { formatAbsoluteTimestamp, formatShortTime } from '../messages/formatMessageTime'
import { formatCallDuration } from './formatCallDuration'

const OUTCOME_CLASSES = {
  Ended: 'text-fg-muted',
  Missed: 'text-danger',
  Declined: 'text-danger',
  Ringing: 'text-fg-muted',
  Accepted: 'text-fg-muted',
}

export function CallEventRow({ call, currentUserId, otherUserDisplayName }) {
  const { t } = useTranslation()
  const isVideo = call.Type === 'Video'
  const isMissedOrDeclined = call.Status === 'Missed' || call.Status === 'Declined'
  const Icon = isMissedOrDeclined ? PhoneMissed : isVideo ? Video : Phone
  const isOwnCall = call.InitiatorId === currentUserId
  const name = otherUserDisplayName || 'this friend'

  let label
  if (call.Status === 'Missed' || call.Status === 'Declined') {
    label = t('calls.missedCall')
  } else if (isOwnCall) {
    label = t(isVideo ? 'calls.youStartedVideoCall' : 'calls.youStartedVoiceCall')
  } else {
    label = t(isVideo ? 'calls.userStartedVideoCall' : 'calls.userStartedVoiceCall', { name })
  }

  return (
    <div className="flex items-center gap-3 px-4 py-1.5">
      <Icon className={cn('size-4 shrink-0', OUTCOME_CLASSES[call.Status] ?? 'text-fg-muted')} aria-hidden="true" />
      <p className="text-sm text-fg-muted">
        {label}
        {call.DurationSeconds != null && <span className="text-fg-muted"> · {formatCallDuration(call.DurationSeconds)}</span>}
      </p>
      <Tooltip content={formatAbsoluteTimestamp(call.Created)}>
        <span className="text-xs text-fg-muted/70">{formatShortTime(call.Created)}</span>
      </Tooltip>
    </div>
  )
}
