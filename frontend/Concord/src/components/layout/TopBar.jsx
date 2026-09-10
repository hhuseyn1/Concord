import { Bell, Hash, Menu, MessageCircle, Phone, PhoneOff, Pin, Search, Users, Video, X } from 'lucide-react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useParams } from 'react-router-dom'
import { useChannels } from '../../features/channels/channelsQueries'
import { DirectMessageSearchPanel } from '../../features/directMessages/DirectMessageSearchPanel'
import { NotificationPanel } from '../../features/notifications/NotificationPanel'
import { PinnedMessagesPanel } from '../../features/messages/PinnedMessagesPanel'
import { useOtherUserDisplayName } from '../../features/directMessages/useOtherUserDisplayName'
import { useNotifications } from '../../hooks/useNotifications'
import { useVoiceCall } from '../../hooks/useVoiceCall'
import { Badge } from '../ui/Badge'
import { IconButton } from '../ui/IconButton'
import { Popover, PopoverContent, PopoverTrigger } from '../ui/Popover'
import { Tooltip } from '../ui/Tooltip'

export function TopBar({ onToggleMembers, membersOpen = false, onToggleSidebar, sidebarOpen = false }) {
  const { t } = useTranslation()
  const { serverId, channelId, conversationId } = useParams()
  const { data: channels } = useChannels(serverId)
  const channel = channelId ? channels?.find((item) => item.Id === channelId) : undefined
  const { unreadCount } = useNotifications()
  const [notificationsOpen, setNotificationsOpen] = useState(false)
  const [searchOpen, setSearchOpen] = useState(false)
  const [pinnedOpen, setPinnedOpen] = useState(false)
  const otherUserDisplayName = useOtherUserDisplayName(conversationId)
  const { activeCall, outgoingCall, startDmCall, cancelOutgoingCall } = useVoiceCall()

  const title = channelId
    ? (channel?.Name ?? 'Loading…')
    : conversationId
      ? (otherUserDisplayName ?? 'Loading…')
      : serverId
        ? `Server ${serverId}`
        : 'Friends'
  const TitleIcon = channelId ? Hash : conversationId ? MessageCircle : Users

  const isRingingThisConversation = outgoingCall?.conversationId === conversationId
  const isBusy = Boolean(activeCall) || Boolean(outgoingCall)

  return (
    <header className="flex h-12 shrink-0 items-center justify-between border-b border-border-subtle bg-surface-base px-4 shadow-sm">
      <div className="flex min-w-0 items-center gap-2">
        {onToggleSidebar && (
          <IconButton
            aria-label={sidebarOpen ? 'Close channel sidebar' : 'Open channel sidebar'}
            variant="ghost"
            // relative z-50: the mobile sidebar's backdrop is a fixed, full-viewport z-40 overlay,
            // which would otherwise sit on top of this button (same screen position, no way to tap
            // it again to close) the moment the drawer opens - keeping this above the overlay's
            // stacking order is what makes it act as an actual open/close toggle instead of only
            // ever opening, with "tap the backdrop" as the sole, undiscoverable way to close it.
            // pointer-events-auto: Radix's modal Dialog (via react-remove-scroll) disables pointer
            // events on background content while open, which this button - outside the Dialog's own
            // Portal - would otherwise inherit; Radix's own Overlay sets this same override on itself
            // for the identical reason.
            className="relative z-50 pointer-events-auto -ml-1 sm:hidden"
            onClick={onToggleSidebar}
          >
            {sidebarOpen ? <X className="size-4" aria-hidden="true" /> : <Menu className="size-4" aria-hidden="true" />}
          </IconButton>
        )}
        <TitleIcon className="size-5 shrink-0 text-fg-muted" aria-hidden="true" />
        <p className="truncate text-sm font-semibold text-fg-heading">{title}</p>
      </div>

      <div className="flex shrink-0 items-center gap-1">
        {conversationId && isRingingThisConversation && (
          <Tooltip content={t('calls.calling')} side="bottom">
            <IconButton aria-label={t('calls.endCall')} variant="danger" onClick={cancelOutgoingCall}>
              <PhoneOff className="size-4" aria-hidden="true" />
            </IconButton>
          </Tooltip>
        )}
        {conversationId && !isRingingThisConversation && (
          <>
            <Tooltip content={t('calls.voiceCall')} side="bottom">
              <IconButton
                aria-label={t('calls.voiceCall')}
                variant="ghost"
                disabled={isBusy}
                onClick={() => startDmCall(conversationId, 'Voice')}
              >
                <Phone className="size-4" aria-hidden="true" />
              </IconButton>
            </Tooltip>
            <Tooltip content={t('calls.videoCall')} side="bottom">
              <IconButton
                aria-label={t('calls.videoCall')}
                variant="ghost"
                disabled={isBusy}
                onClick={() => startDmCall(conversationId, 'Video')}
              >
                <Video className="size-4" aria-hidden="true" />
              </IconButton>
            </Tooltip>
          </>
        )}
        {conversationId && (
          <Popover open={searchOpen} onOpenChange={setSearchOpen}>
            <Tooltip content={t('messages.searchPlaceholder')} side="bottom">
              <PopoverTrigger asChild>
                <IconButton
                  aria-label={t('messages.searchPlaceholder')}
                  variant={searchOpen ? 'secondary' : 'ghost'}
                >
                  <Search className="size-4" aria-hidden="true" />
                </IconButton>
              </PopoverTrigger>
            </Tooltip>
            <PopoverContent side="bottom" align="end" className="w-auto p-0">
              <DirectMessageSearchPanel conversationId={conversationId} onNavigateToResult={() => setSearchOpen(false)} />
            </PopoverContent>
          </Popover>
        )}
        {(channelId || conversationId) && (
          <Popover open={pinnedOpen} onOpenChange={setPinnedOpen}>
            <Tooltip content={t('messages.pinnedMessages')} side="bottom">
              <PopoverTrigger asChild>
                <IconButton aria-label={t('messages.pinnedMessages')} variant={pinnedOpen ? 'secondary' : 'ghost'}>
                  <Pin className="size-4" aria-hidden="true" />
                </IconButton>
              </PopoverTrigger>
            </Tooltip>
            <PopoverContent side="bottom" align="end" className="w-auto p-0">
              {channelId ? (
                <PinnedMessagesPanel serverId={serverId} channelId={channelId} onNavigateToResult={() => setPinnedOpen(false)} />
              ) : (
                <PinnedMessagesPanel conversationId={conversationId} onNavigateToResult={() => setPinnedOpen(false)} />
              )}
            </PopoverContent>
          </Popover>
        )}
        <Tooltip content="Member list" side="bottom">
          <IconButton
            aria-label="Toggle member list"
            variant={membersOpen ? 'secondary' : 'ghost'}
            onClick={onToggleMembers}
          >
            <Users className="size-4" aria-hidden="true" />
          </IconButton>
        </Tooltip>
        <Popover open={notificationsOpen} onOpenChange={setNotificationsOpen}>
          <Tooltip content="Notifications" side="bottom">
            <PopoverTrigger asChild>
              <IconButton
                aria-label={unreadCount > 0 ? `Notifications (${unreadCount} unread)` : 'Notifications'}
                variant={notificationsOpen ? 'secondary' : 'ghost'}
                className="relative"
              >
                <Bell className="size-4" aria-hidden="true" />
                {unreadCount > 0 && (
                  <Badge
                    variant="danger"
                    className="absolute -top-1 -right-1 min-w-4 justify-center px-1 py-0 text-[0.625rem] leading-tight"
                  >
                    {unreadCount > 99 ? '99+' : unreadCount}
                  </Badge>
                )}
              </IconButton>
            </PopoverTrigger>
          </Tooltip>
          <PopoverContent side="bottom" align="end" className="w-auto p-0">
            <NotificationPanel onNavigate={() => setNotificationsOpen(false)} />
          </PopoverContent>
        </Popover>
      </div>
    </header>
  )
}
