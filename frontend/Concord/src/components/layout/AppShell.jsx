import * as Dialog from '@radix-ui/react-dialog'
import { useEffect, useState } from 'react'
import { useLocation, useMatch, useNavigate, useParams } from 'react-router-dom'
import { useChannelNavigationShortcuts } from '../../features/channels/useChannelNavigationShortcuts'
import { MemberListPanel } from '../../features/members/MemberListPanel'
import { GlobalSearchModal } from '../../features/search/GlobalSearchModal'
import { useServerLiveUpdates } from '../../features/servers/useServerLiveUpdates'
import { VoiceCallStrip } from '../../features/voice/VoiceCallStrip'
import { useGlobalKeyboardShortcuts } from '../../hooks/useGlobalKeyboardShortcuts'
import { setNavigate } from '../../lib/navigation'
import { ChannelSidebar } from './ChannelSidebar'
import { ConnectionStatusBanner } from './ConnectionStatusBanner'
import { MessageAreaShell } from './MessageAreaShell'
import { ServerRail } from './ServerRail'
import { TopBar } from './TopBar'

export function AppShell() {
  const [membersOpen, setMembersOpen] = useState(false)
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false)
  const [isDesktopMembers, setIsDesktopMembers] = useState(
    () => typeof window !== 'undefined' && window.matchMedia('(min-width: 768px)').matches,
  )
  const location = useLocation()
  const navigate = useNavigate()
  const { serverId } = useParams()
  useServerLiveUpdates(serverId)
  useChannelNavigationShortcuts()
  const { isSearchOpen, setSearchOpen } = useGlobalKeyboardShortcuts()

  useEffect(() => {
    setNavigate(navigate)
    return () => setNavigate(null)
  }, [navigate])

  useEffect(() => {
    const query = window.matchMedia('(min-width: 640px)')
    const handleChange = (event) => {
      if (event.matches) setMobileSidebarOpen(false)
    }
    query.addEventListener('change', handleChange)
    return () => query.removeEventListener('change', handleChange)
  }, [])

  useEffect(() => {
    const query = window.matchMedia('(min-width: 768px)')
    const handleChange = (event) => setIsDesktopMembers(event.matches)
    query.addEventListener('change', handleChange)
    return () => query.removeEventListener('change', handleChange)
  }, [])
  const isDmRoute = useMatch('/cabinet/dm/:conversationId')
  const [prevPathname, setPrevPathname] = useState(location.pathname)
  if (location.pathname !== prevPathname) {
    setPrevPathname(location.pathname)
    setMobileSidebarOpen(false)
    if (!isDesktopMembers) setMembersOpen(false)
  }

  return (
    <div className="flex h-dvh w-full overflow-hidden bg-surface-base text-fg-default">
      <ServerRail />
      <ChannelSidebar className="hidden sm:flex" />

      <Dialog.Root open={mobileSidebarOpen} onOpenChange={setMobileSidebarOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 z-40 bg-black/60 sm:hidden motion-safe:data-[state=open]:animate-overlay-in motion-safe:data-[state=closed]:animate-overlay-out" />
          <Dialog.Content
            aria-describedby={undefined}
            className="fixed top-0 left-[72px] z-40 flex h-dvh outline-none sm:hidden motion-safe:data-[state=open]:animate-drawer-in motion-safe:data-[state=closed]:animate-drawer-out"
          >
            <Dialog.Title className="sr-only">Channel navigation</Dialog.Title>
            <ChannelSidebar className="flex" />
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>

      <div className="flex min-w-0 flex-1 flex-col">
        <ConnectionStatusBanner />
        <VoiceCallStrip className="sm:hidden" />
        <TopBar
          onToggleMembers={() => setMembersOpen((open) => !open)}
          membersOpen={membersOpen}
          onToggleSidebar={() => setMobileSidebarOpen((open) => !open)}
          sidebarOpen={mobileSidebarOpen}
        />
        <MessageAreaShell membersOpen={membersOpen && !isDmRoute} memberPanel={<MemberListPanel />} />
      </div>

      {!isDesktopMembers && (
        <Dialog.Root open={membersOpen && !isDmRoute} onOpenChange={setMembersOpen}>
          <Dialog.Portal>
            <Dialog.Overlay className="fixed inset-0 z-40 bg-black/60 motion-safe:data-[state=open]:animate-overlay-in motion-safe:data-[state=closed]:animate-overlay-out" />
            <Dialog.Content
              aria-describedby={undefined}
              className="fixed top-0 right-0 z-40 flex h-dvh w-60 max-w-[80vw] flex-col border-l border-border-default bg-surface-sidebar outline-none motion-safe:data-[state=open]:animate-drawer-in-right motion-safe:data-[state=closed]:animate-drawer-out-right"
            >
              <Dialog.Title className="sr-only">Members</Dialog.Title>
              <MemberListPanel />
            </Dialog.Content>
          </Dialog.Portal>
        </Dialog.Root>
      )}

      <GlobalSearchModal open={isSearchOpen} onOpenChange={setSearchOpen} />
    </div>
  )
}
