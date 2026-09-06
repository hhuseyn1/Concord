import { useQueryClient } from '@tanstack/react-query'
import { Link, useParams } from 'react-router-dom'
import { useChannels } from '../channels/channelsQueries'
import { directMessagesKeys, flattenConversationPages } from '../directMessages/directMessagesQueries'
import { useVoiceCall } from '../../hooks/useVoiceCall'
import { cn } from '../../lib/cn'
import { VoiceCallControls } from './VoiceCallControls'

export function VoiceCallStrip({ className }) {
  const { serverId, channelId, conversationId } = useParams()
  const queryClient = useQueryClient()
  const {
    activeCall,
    isMuted,
    isDeafened,
    isVideoEnabled,
    isScreenSharing,
    toggleMute,
    toggleDeafen,
    toggleVideo,
    toggleScreenShare,
    leaveCall,
  } = useVoiceCall()
  const isChannelCall = activeCall?.kind === 'channel'
  const { data: channels } = useChannels(isChannelCall ? activeCall.serverId : undefined, { enabled: isChannelCall })

  if (!activeCall) return null
  if (isChannelCall && activeCall.serverId === serverId && activeCall.channelId === channelId) return null
  if (activeCall.kind === 'dm' && activeCall.conversationId === conversationId) return null

  let label
  let linkTo
  if (isChannelCall) {
    const channel = channels?.find((item) => item.Id === activeCall.channelId)
    label = channel?.Name ?? 'Voice channel'
    linkTo = `/cabinet/servers/${activeCall.serverId}/channels/${activeCall.channelId}`
  } else {
    const cached = queryClient.getQueryData(directMessagesKeys.conversations())
    const conversation = flattenConversationPages(cached?.pages).find((item) => item.Id === activeCall.conversationId)
    const otherUser = conversation?.OtherUser
    label = otherUser?.Username || [otherUser?.Name, otherUser?.Surname].filter(Boolean).join(' ') || 'Direct call'
    linkTo = `/cabinet/dm/${activeCall.conversationId}`
  }

  return (
    <div className={cn('flex items-center gap-2 border-t border-border-subtle bg-surface-sidebar px-3 py-2', className)}>
      <div className="min-w-0 flex-1">
        <p className="text-xs font-semibold tracking-wide text-success uppercase">
          {isChannelCall ? 'Voice connected' : 'Call connected'}
        </p>
        <Link
          to={linkTo}
          className="block truncate text-sm font-medium text-fg-default hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand"
        >
          {label}
        </Link>
      </div>
      <VoiceCallControls
        isMuted={isMuted}
        isDeafened={isDeafened}
        isVideoEnabled={isVideoEnabled}
        isScreenSharing={isScreenSharing}
        onToggleMute={toggleMute}
        onToggleDeafen={toggleDeafen}
        onToggleVideo={toggleVideo}
        onToggleScreenShare={toggleScreenShare}
        onLeave={leaveCall}
        size="sm"
      />
    </div>
  )
}
