import { AppShell } from '../components/layout/AppShell'
import { DirectMessagesProvider } from './DirectMessagesProvider'
import { NotificationsProvider } from './NotificationsProvider'
import { PresenceProvider } from './PresenceProvider'
import { VoiceCallProvider } from './VoiceCallProvider'

// Everything these providers pull in (livekit-client for voice/video, the SignalR hub wrappers)
// is only ever needed once a signed-in user is actually inside the app - not on the public
// landing page, /login, or /register. Bundling them here (rather than around the whole <App>)
// keeps that code out of the chunk an anonymous visitor downloads, since this module is only
// ever reached via the lazy `import()` on the '/cabinet' route in lib/router.jsx.
export function CabinetRoot() {
  return (
    <PresenceProvider>
      <NotificationsProvider>
        <DirectMessagesProvider>
          <VoiceCallProvider>
            <AppShell />
          </VoiceCallProvider>
        </DirectMessagesProvider>
      </NotificationsProvider>
    </PresenceProvider>
  )
}
