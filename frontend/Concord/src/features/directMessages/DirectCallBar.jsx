import { AlertTriangle } from 'lucide-react'
import { useMemo } from 'react'
import { useAuth } from '../../hooks/useAuth'
import { useVoiceCall } from '../../hooks/useVoiceCall'
import { ParticipantTile } from '../voice/ParticipantTile'
import { useActiveScreenShareId } from '../voice/useActiveScreenShareId'
import { VoiceCallControls } from '../voice/VoiceCallControls'

export function DirectCallBar({ conversationId }) {
  const { user } = useAuth()
  const {
    activeCall,
    participants,
    room,
    isMuted,
    isDeafened,
    isVideoEnabled,
    isScreenSharing,
    isReconnecting,
    leaveCall,
    toggleMute,
    toggleDeafen,
    toggleVideo,
    toggleScreenShare,
    isScreenShareSupported,
  } = useVoiceCall()

  const isInThisCall = activeCall?.kind === 'dm' && activeCall.conversationId === conversationId
  const screenSharerId = useActiveScreenShareId(room)

  const tiles = useMemo(() => {
    const list = Object.values(participants)
    if (isInThisCall && user?.Id && !participants[user.Id]) {
      list.push({ UserId: user.Id, Identity: user.Username ?? user.Id })
    }
    return list
  }, [participants, isInThisCall, user])

  const spotlightTile = screenSharerId ? tiles.find((tile) => tile.UserId === screenSharerId) : null
  const stripTiles = spotlightTile ? tiles.filter((tile) => tile.UserId !== screenSharerId) : tiles

  if (!isInThisCall) {
    return null
  }

  return (
    <div className="flex shrink-0 flex-col gap-2 border-b border-border-subtle bg-surface-sidebar px-4 py-3">
      {isReconnecting && (
        <div className="flex items-center justify-center gap-2 rounded-md bg-warning-bg px-3 py-1.5 text-sm text-warning">
          <AlertTriangle className="size-4 shrink-0 animate-pulse" aria-hidden="true" />
          Reconnecting…
        </div>
      )}
      {spotlightTile ? (
        <div className="flex flex-col gap-2">
          <div className="h-64 w-full sm:h-80">
            <ParticipantTile participant={spotlightTile} isLocal={spotlightTile.UserId === user?.Id} spotlight />
          </div>
          {stripTiles.length > 0 && (
            <div className="flex flex-wrap justify-center gap-2">
              {stripTiles.map((participant) => (
                <div key={participant.UserId} className="w-28">
                  <ParticipantTile participant={participant} isLocal={participant.UserId === user?.Id} />
                </div>
              ))}
            </div>
          )}
        </div>
      ) : (
        <div className="flex flex-wrap justify-center gap-3">
          {tiles.map((participant) => (
            <div key={participant.UserId} className="w-full max-w-64 sm:w-64">
              <ParticipantTile participant={participant} isLocal={participant.UserId === user?.Id} />
            </div>
          ))}
        </div>
      )}
      <div className="flex justify-center">
        <VoiceCallControls
          isMuted={isMuted}
          isDeafened={isDeafened}
          isVideoEnabled={isVideoEnabled}
          isScreenSharing={isScreenSharing}
          onToggleMute={toggleMute}
          onToggleDeafen={toggleDeafen}
          onToggleVideo={toggleVideo}
          onToggleScreenShare={isScreenShareSupported ? toggleScreenShare : undefined}
          onLeave={leaveCall}
          size="sm"
        />
      </div>
    </div>
  )
}
