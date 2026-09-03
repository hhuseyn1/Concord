import {
  Headphones,
  HeadphoneOff,
  Mic,
  MicOff,
  MonitorOff,
  MonitorUp,
  PhoneOff,
  Video,
  VideoOff,
} from 'lucide-react'
import { IconButton } from '../../components/ui/IconButton'
import { Tooltip } from '../../components/ui/Tooltip'
import { cn } from '../../lib/cn'

export function VoiceCallControls({
  isMuted,
  isDeafened,
  isVideoEnabled = false,
  isScreenSharing = false,
  onToggleMute,
  onToggleDeafen,
  onToggleVideo,
  onToggleScreenShare,
  onLeave,
  size = 'md',
  className,
}) {
  return (
    <div className={cn('flex items-center gap-1', className)}>
      <Tooltip content={isMuted ? 'Unmute microphone' : 'Mute microphone'}>
        <IconButton
          aria-label={isMuted ? 'Unmute microphone' : 'Mute microphone'}
          variant={isMuted ? 'danger' : 'secondary'}
          size={size}
          onClick={onToggleMute}
        >
          {isMuted ? (
            <MicOff key="muted" className="motion-safe:animate-icon-toggle" aria-hidden="true" />
          ) : (
            <Mic key="unmuted" className="motion-safe:animate-icon-toggle" aria-hidden="true" />
          )}
        </IconButton>
      </Tooltip>
      <Tooltip content={isDeafened ? 'Undeafen' : 'Deafen'}>
        <IconButton
          aria-label={isDeafened ? 'Undeafen' : 'Deafen'}
          variant={isDeafened ? 'danger' : 'secondary'}
          size={size}
          onClick={onToggleDeafen}
        >
          {isDeafened ? (
            <HeadphoneOff key="deafened" className="motion-safe:animate-icon-toggle" aria-hidden="true" />
          ) : (
            <Headphones key="undeafened" className="motion-safe:animate-icon-toggle" aria-hidden="true" />
          )}
        </IconButton>
      </Tooltip>
      {onToggleVideo && (
        <Tooltip content={isVideoEnabled ? 'Turn off camera' : 'Turn on camera'}>
          <IconButton
            aria-label={isVideoEnabled ? 'Turn off camera' : 'Turn on camera'}
            variant={isVideoEnabled ? 'primary' : 'secondary'}
            size={size}
            onClick={onToggleVideo}
          >
            {isVideoEnabled ? (
              <Video key="video-on" className="motion-safe:animate-icon-toggle" aria-hidden="true" />
            ) : (
              <VideoOff key="video-off" className="motion-safe:animate-icon-toggle" aria-hidden="true" />
            )}
          </IconButton>
        </Tooltip>
      )}
      {onToggleScreenShare && (
        <Tooltip content={isScreenSharing ? 'Stop sharing screen' : 'Share screen'}>
          <IconButton
            aria-label={isScreenSharing ? 'Stop sharing screen' : 'Share screen'}
            variant={isScreenSharing ? 'primary' : 'secondary'}
            size={size}
            onClick={onToggleScreenShare}
          >
            {isScreenSharing ? (
              <MonitorOff key="share-on" className="motion-safe:animate-icon-toggle" aria-hidden="true" />
            ) : (
              <MonitorUp key="share-off" className="motion-safe:animate-icon-toggle" aria-hidden="true" />
            )}
          </IconButton>
        </Tooltip>
      )}
      <Tooltip content="Leave call">
        <IconButton aria-label="Leave call" variant="danger" size={size} onClick={onLeave}>
          <PhoneOff aria-hidden="true" />
        </IconButton>
      </Tooltip>
    </div>
  )
}
