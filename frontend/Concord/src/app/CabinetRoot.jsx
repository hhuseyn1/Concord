import { AppShell } from '../components/layout/AppShell'
import { PendingInviteHandler } from '../features/servers/PendingInviteHandler'
import { DirectMessagesProvider } from './DirectMessagesProvider'
import { NotificationsProvider } from './NotificationsProvider'
import { PresenceProvider } from './PresenceProvider'
import { VoiceCallProvider } from './VoiceCallProvider'

export function CabinetRoot() {
  return (
    <PresenceProvider>
      <NotificationsProvider>
        <DirectMessagesProvider>
          <VoiceCallProvider>
            <PendingInviteHandler />
            <AppShell />
          </VoiceCallProvider>
        </DirectMessagesProvider>
      </NotificationsProvider>
    </PresenceProvider>
  )
}
