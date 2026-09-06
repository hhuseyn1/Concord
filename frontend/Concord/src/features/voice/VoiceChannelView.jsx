import { AlertTriangle, Volume2 } from 'lucide-react'
import { useMemo } from 'react'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { ScrollArea } from '../../components/ui/ScrollArea'
import { Spinner } from '../../components/ui/Spinner'
import { useAuth } from '../../hooks/useAuth'
import { useVoiceCall } from '../../hooks/useVoiceCall'
import { ParticipantTile } from './ParticipantTile'
import { useActiveScreenShareId } from './useActiveScreenShareId'
import { VoiceCallControls } from './VoiceCallControls'

export function VoiceChannelView({ channel, serverId, channelId }) {
  const { user } = useAuth()
  const {
    activeCall,
    participants,
    room,
    isConnecting,
    isMuted,
    isDeafened,
    isVideoEnabled,
    isScreenSharing,
    isReconnecting,
    joinCall,
    leaveCall,
    toggleMute,
    toggleDeafen,
    toggleVideo,
    toggleScreenShare,
    isScreenShareSupported,
  } = useVoiceCall()

  const isInThisCall = activeCall?.kind === 'channel' && activeCall.channelId === channelId
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
    return (
      <div className="flex flex-1 items-center justify-center p-8">
        <EmptyState
          icon={Volume2}
          title={channel?.Name ? `Join ${channel.Name}` : 'Join voice channel'}
          description="Connect to start talking with everyone in this channel."
          action={
            <Button onClick={() => joinCall(serverId, channelId)} disabled={isConnecting}>
              {isConnecting && <Spinner size="sm" />}
              {isConnecting ? 'Connecting…' : 'Join Voice'}
            </Button>
          }
        />
      </div>
    )
  }

  return (
    <div className="flex h-full min-h-0 flex-col">
      {isReconnecting && (
        <div className="flex shrink-0 items-center justify-center gap-2 border-b border-warning/30 bg-warning-bg px-3 py-2 text-sm text-warning">
          <AlertTriangle className="size-4 shrink-0 animate-pulse" aria-hidden="true" />
          Reconnecting…
        </div>
      )}
      {spotlightTile ? (
        <div className="flex min-h-0 flex-1 flex-col gap-3 p-4 sm:gap-4 sm:p-6">
          <div className="min-h-0 flex-1">
            <ParticipantTile participant={spotlightTile} isLocal={spotlightTile.UserId === user?.Id} spotlight />
          </div>
          {stripTiles.length > 0 && (
            <ScrollArea orientation="horizontal" className="shrink-0">
              <div className="flex gap-3">
                {stripTiles.map((participant) => (
                  <div key={participant.UserId} className="w-40 shrink-0">
                    <ParticipantTile participant={participant} isLocal={participant.UserId === user?.Id} />
                  </div>
                ))}
              </div>
            </ScrollArea>
          )}
        </div>
      ) : (
        <ScrollArea className="min-h-0 flex-1">
          <div className="grid grid-cols-[repeat(auto-fill,minmax(160px,1fr))] gap-3 p-4 sm:gap-4 sm:p-6">
            {tiles.map((participant) => (
              <ParticipantTile
                key={participant.UserId}
                participant={participant}
                isLocal={participant.UserId === user?.Id}
              />
            ))}
          </div>
        </ScrollArea>
      )}
      <div className="flex shrink-0 items-center justify-center border-t border-border-subtle bg-surface-sidebar p-3">
        <div className="rounded-2xl bg-surface-sidebar shadow-md ring-1 ring-border-default px-3 py-2">
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
            size="lg"
          />
        </div>
      </div>
    </div>
  )
}
