import { ConnectionQuality, ParticipantEvent, Track } from 'livekit-client'
import { Maximize2, MicOff, SignalHigh, SignalLow, SignalMedium, SignalZero, Volume1, Volume2, VolumeX } from 'lucide-react'
import { useEffect, useRef, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import * as usersService from '../../api/usersService'
import { Avatar } from '../../components/ui/Avatar'
import { Popover, PopoverContent, PopoverTrigger } from '../../components/ui/Popover'
import { Tooltip } from '../../components/ui/Tooltip'
import { useVoiceCall } from '../../hooks/useVoiceCall'
import { cn } from '../../lib/cn'
import { toAvatarPresence } from '../friends/presence'
import { ProfilePopover } from '../members/ProfilePopover'

function useParticipantVideoTrack(identity) {
  const { room } = useVoiceCall()
  const [videoTrack, setVideoTrack] = useState(null)
  const [isScreenShare, setIsScreenShare] = useState(false)

  useEffect(() => {
    if (!room || !identity) return undefined

    const participant = room.getParticipantByIdentity(identity)
    if (!participant) return undefined

    const update = () => {
      const publications = Array.from(participant.videoTrackPublications.values())
      const screenPub = publications.find((pub) => pub.source === Track.Source.ScreenShare && pub.track)
      const cameraPub = publications.find((pub) => pub.source === Track.Source.Camera && pub.track)
      const active = screenPub ?? cameraPub
      setVideoTrack(active?.track ?? null)
      setIsScreenShare(Boolean(screenPub?.track))
    }

    update()

    const events = [
      ParticipantEvent.TrackSubscribed,
      ParticipantEvent.TrackUnsubscribed,
      ParticipantEvent.TrackMuted,
      ParticipantEvent.TrackUnmuted,
      ParticipantEvent.LocalTrackPublished,
      ParticipantEvent.LocalTrackUnpublished,
    ]
    for (const event of events) participant.on(event, update)
    return () => {
      for (const event of events) participant.off(event, update)
      setVideoTrack(null)
      setIsScreenShare(false)
    }
  }, [room, identity])

  return { videoTrack, isScreenShare }
}

function useParticipantMicMuted(identity) {
  const { room } = useVoiceCall()
  const [isMicMuted, setIsMicMuted] = useState(false)

  useEffect(() => {
    if (!room || !identity) return undefined

    const participant = room.getParticipantByIdentity(identity)
    if (!participant) return undefined

    const update = () => setIsMicMuted(!participant.isMicrophoneEnabled)
    update()

    const events = [
      ParticipantEvent.TrackPublished,
      ParticipantEvent.TrackUnpublished,
      ParticipantEvent.TrackMuted,
      ParticipantEvent.TrackUnmuted,
      ParticipantEvent.LocalTrackPublished,
      ParticipantEvent.LocalTrackUnpublished,
    ]
    for (const event of events) participant.on(event, update)
    return () => {
      for (const event of events) participant.off(event, update)
      setIsMicMuted(false)
    }
  }, [room, identity])

  return isMicMuted
}

function useParticipantConnectionQuality(identity) {
  const { room } = useVoiceCall()
  const [quality, setQuality] = useState(ConnectionQuality.Unknown)

  useEffect(() => {
    if (!room || !identity) return undefined

    const participant = room.getParticipantByIdentity(identity)
    if (!participant) return undefined

    const update = () => setQuality(participant.connectionQuality)
    update()

    participant.on(ParticipantEvent.ConnectionQualityChanged, update)
    return () => {
      participant.off(ParticipantEvent.ConnectionQualityChanged, update)
      setQuality(ConnectionQuality.Unknown)
    }
  }, [room, identity])

  return quality
}

function ConnectionQualityIcon({ quality }) {
  if (quality === ConnectionQuality.Unknown) return null
  const config = {
    [ConnectionQuality.Excellent]: { Icon: SignalHigh, className: 'text-success', label: 'Excellent connection' },
    [ConnectionQuality.Good]: { Icon: SignalMedium, className: 'text-success', label: 'Good connection' },
    [ConnectionQuality.Poor]: { Icon: SignalLow, className: 'text-warning', label: 'Poor connection' },
    [ConnectionQuality.Lost]: { Icon: SignalZero, className: 'text-danger', label: 'Connection lost' },
  }[quality]
  if (!config) return null
  const { Icon, className, label } = config
  return (
    <Tooltip content={label}>
      <Icon className={cn('size-3.5', className)} aria-hidden="true" />
    </Tooltip>
  )
}

function ParticipantVolumeControl({ userId, displayName, volume, onVolumeChange, dark = false }) {
  const VolumeIcon = volume === 0 ? VolumeX : volume < 1 ? Volume1 : Volume2
  return (
    <Popover>
      <PopoverTrigger asChild>
        <button
          type="button"
          aria-label={`Volume for ${displayName}`}
          onClick={(event) => event.stopPropagation()}
          className={cn(
            'flex size-5 shrink-0 items-center justify-center rounded-full transition-colors',
            dark
              ? 'bg-black/60 text-white hover:bg-black/80'
              : 'bg-surface-2 text-fg-muted hover:bg-surface-2/80 hover:text-fg-default',
          )}
        >
          <VolumeIcon className="size-3" aria-hidden="true" />
        </button>
      </PopoverTrigger>
      <PopoverContent
        side="top"
        align="center"
        className="w-48"
        onClick={(event) => event.stopPropagation()}
        onPointerDown={(event) => event.stopPropagation()}
      >
        <p className="mb-2 truncate text-xs font-medium text-fg-muted">{displayName}&rsquo;s volume</p>
        <input
          type="range"
          min={0}
          max={1}
          step={0.05}
          value={volume}
          onChange={(event) => onVolumeChange(userId, Number(event.target.value))}
          className="w-full accent-brand"
          aria-label={`Volume for ${displayName}`}
        />
      </PopoverContent>
    </Popover>
  )
}

export function ParticipantTile({ participant, isLocal = false, spotlight = false }) {
  const { activeSpeakers, participantVolumes, setParticipantVolume } = useVoiceCall()
  const { data: profile } = useQuery({
    queryKey: ['users', participant.UserId],
    queryFn: () => usersService.getUserById(participant.UserId),
    enabled: Boolean(participant.UserId),
    staleTime: 5 * 60 * 1000,
  })

  const { videoTrack, isScreenShare } = useParticipantVideoTrack(participant.UserId)
  const isMicMuted = useParticipantMicMuted(participant.UserId)
  const connectionQuality = useParticipantConnectionQuality(participant.UserId)
  const isConnectionLost = connectionQuality === ConnectionQuality.Lost
  const isSpeaking = activeSpeakers.has(participant.UserId)
  const videoRef = useRef(null)

  useEffect(() => {
    const el = videoRef.current
    if (!videoTrack || !el) return undefined
    videoTrack.attach(el)
    return () => videoTrack.detach(el)
  }, [videoTrack])

  const displayName =
    profile?.Username ||
    [profile?.Name, profile?.Surname].filter(Boolean).join(' ') ||
    participant.Identity ||
    'Unknown user'

  const micBadge = isMicMuted && (
    <Tooltip content={`${displayName} is muted`}>
      <span className="flex size-5 shrink-0 items-center justify-center rounded-full bg-danger-solid text-fg-on-danger">
        <MicOff className="size-3" aria-hidden="true" />
      </span>
    </Tooltip>
  )

  const volumeControl = !isLocal && (
    <ParticipantVolumeControl
      userId={participant.UserId}
      displayName={displayName}
      volume={participantVolumes[participant.UserId] ?? 1}
      onVolumeChange={setParticipantVolume}
      dark={Boolean(videoTrack)}
    />
  )

  const requestFullscreen = () => {
    videoRef.current?.requestFullscreen?.().catch((error) => {
      console.error('Failed to enter fullscreen', error)
    })
  }

  const card = videoTrack ? (
    <div
      className={cn(
        'relative flex flex-col overflow-hidden rounded-lg border border-border-subtle bg-black',
        spotlight ? 'h-full w-full' : 'aspect-video w-full',
        isSpeaking && 'ring-2 ring-brand',
        isConnectionLost && 'opacity-50',
      )}
    >
      <video
        ref={videoRef}
        muted
        playsInline
        autoPlay
        className={cn(
          'h-full w-full',
          isScreenShare ? 'object-contain' : 'object-cover',
          isLocal && !isScreenShare && 'scale-x-[-1]',
        )}
      />
      <div className="absolute top-1.5 right-1.5 flex items-center gap-1">
        {volumeControl}
        <Tooltip content="Fullscreen">
          <button
            type="button"
            aria-label="Fullscreen"
            onClick={(event) => {
              event.stopPropagation()
              requestFullscreen()
            }}
            className="flex size-5 shrink-0 items-center justify-center rounded-full bg-black/60 text-white transition-colors hover:bg-black/80"
          >
            <Maximize2 className="size-3" aria-hidden="true" />
          </button>
        </Tooltip>
      </div>
      <div className="absolute bottom-1.5 left-2 flex items-center gap-1.5">
        <p className="rounded bg-black/60 px-1.5 py-0.5 text-xs font-medium text-white">
          {displayName}
          {isLocal ? ' (you)' : ''}
          {isScreenShare ? ' - sharing screen' : ''}
          {isConnectionLost ? ' - connection lost' : ''}
        </p>
        <ConnectionQualityIcon quality={connectionQuality} />
        {micBadge}
      </div>
    </div>
  ) : (
    <div
      className={cn(
        'flex flex-col items-center gap-2 rounded-lg border border-border-subtle bg-surface-floating p-4',
        isSpeaking && 'ring-2 ring-brand',
        isConnectionLost && 'opacity-50',
      )}
    >
      <div className="relative">
        <Avatar
          src={profile?.AvatarUrl ?? undefined}
          name={displayName}
          presence={profile ? toAvatarPresence(profile.Status) : undefined}
          size="lg"
        />
        {micBadge && <span className="absolute -right-1 -bottom-1">{micBadge}</span>}
      </div>
      <p className="max-w-full truncate text-sm font-medium text-fg-default">
        {displayName}
        {isLocal ? ' (you)' : ''}
      </p>
      {(connectionQuality !== ConnectionQuality.Unknown || volumeControl) && (
        <div className="flex items-center gap-1.5">
          <ConnectionQualityIcon quality={connectionQuality} />
          {volumeControl}
        </div>
      )}
      {isConnectionLost && <p className="text-xs text-danger">Connection lost</p>}
    </div>
  )

  if (isLocal) return card

  return (
    <ProfilePopover userId={participant.UserId} side="top" align="center">
      <div
        role="button"
        tabIndex={0}
        onKeyDown={(event) => {
          if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault()
            event.currentTarget.click()
          }
        }}
        className="rounded-lg text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand"
      >
        {card}
      </div>
    </ProfilePopover>
  )
}
