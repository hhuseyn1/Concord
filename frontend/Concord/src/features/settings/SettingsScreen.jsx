import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useSearchParams } from 'react-router-dom'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../../components/ui/Tabs'
import { AccountSettingsForm } from './AccountSettingsForm'
import { ActiveSessionsSection } from './ActiveSessionsSection'
import { BillingSettingsSection } from './BillingSettingsSection'
import { ChangePasswordForm } from './ChangePasswordForm'
import { DeleteAccountSection } from './DeleteAccountSection'
import { PreferencesSection } from './PreferencesSection'
import { PrivacySettingsSection } from './PrivacySettingsSection'
import { ServersSettingsTab } from './ServersSettingsTab'
import { ShortcutsSection } from './ShortcutsSection'
import { TwoFactorSection } from './TwoFactorSection'
import { VoiceVideoSettingsSection } from './VoiceVideoSettingsSection'

const TAB_VALUES = ['account', 'privacy', 'voice', 'servers', 'billing']
const DEFAULT_TAB = 'account'

export function SettingsScreen() {
  const { t } = useTranslation()
  const [searchParams] = useSearchParams()
  // Only used to pick the initial tab (e.g. a Stripe Customer Portal return URL linking
  // straight to `?tab=billing`) - the tab state itself isn't kept in sync with the URL after
  // that, so switching tabs manually doesn't rewrite the address bar.
  const [tab, setTab] = useState(() => {
    const requested = searchParams.get('tab')
    return TAB_VALUES.includes(requested) ? requested : DEFAULT_TAB
  })

  return (
    <div className="flex flex-1 flex-col gap-4 overflow-y-auto p-6">
      <div>
        <h1 className="text-lg font-semibold text-fg-heading">{t('settings.title')}</h1>
        <p className="text-sm text-fg-muted">{t('settings.subtitle')}</p>
      </div>

      <Tabs value={tab} onValueChange={setTab}>
        <TabsList>
          <TabsTrigger value="account">{t('settings.myAccount')}</TabsTrigger>
          <TabsTrigger value="privacy">{t('privacy.title')}</TabsTrigger>
          <TabsTrigger value="voice">{t('voice.title')}</TabsTrigger>
          <TabsTrigger value="servers">{t('settings.servers')}</TabsTrigger>
          <TabsTrigger value="billing">{t('billing.title')}</TabsTrigger>
        </TabsList>

        <TabsContent value="account">
          <div className="flex flex-col gap-8">
            <AccountSettingsForm />
            <div className="max-w-md border-t border-border-subtle pt-6">
              <h2 className="mb-4 text-sm font-semibold text-fg-heading">{t('settings.changePassword')}</h2>
              <ChangePasswordForm />
            </div>
            <div className="max-w-md border-t border-border-subtle pt-6">
              <TwoFactorSection />
            </div>
            <div className="max-w-md border-t border-border-subtle pt-6">
              <PreferencesSection />
            </div>
            <div className="max-w-md border-t border-border-subtle pt-6">
              <ActiveSessionsSection />
            </div>
            <div className="max-w-md border-t border-border-subtle pt-6">
              <ShortcutsSection />
            </div>
            <div className="max-w-md border-t border-border-subtle pt-6">
              <DeleteAccountSection />
            </div>
          </div>
        </TabsContent>
        <TabsContent value="privacy">
          <PrivacySettingsSection />
        </TabsContent>
        <TabsContent value="voice">
          <VoiceVideoSettingsSection />
        </TabsContent>
        <TabsContent value="servers">
          <ServersSettingsTab />
        </TabsContent>
        <TabsContent value="billing">
          <BillingSettingsSection />
        </TabsContent>
      </Tabs>
    </div>
  )
}
