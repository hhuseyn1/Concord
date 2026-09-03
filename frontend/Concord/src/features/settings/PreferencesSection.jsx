import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Switch } from '../../components/ui/Switch'
import { toast } from '../../components/ui/Toast'
import { useAuth } from '../../hooks/useAuth'
import {
  isDesktopNotificationsEnabled,
  requestNotificationPermission,
  setDesktopNotificationsEnabled,
} from '../../lib/desktopNotifications'
import { toServerLocale } from '../../i18n/localeMapping'
import { LanguageSwitcher } from './LanguageSwitcher'
import { useUpdatePreferencesMutation } from './settingsQueries'

export function PreferencesSection() {
  const { t, i18n } = useTranslation()
  const { user } = useAuth()
  const updatePreferencesMutation = useUpdatePreferencesMutation()
  const [desktopEnabled, setDesktopEnabled] = useState(() => isDesktopNotificationsEnabled())

  if (!user) return null

  const handleToggleDesktop = async (checked) => {
    if (checked) {
      const permission = await requestNotificationPermission()
      if (permission !== 'granted') {
        toast({ variant: 'danger', description: t('desktopNotifications.permissionDenied') })
        setDesktopNotificationsEnabled(false)
        setDesktopEnabled(false)
        return
      }
    }
    setDesktopNotificationsEnabled(checked)
    setDesktopEnabled(checked)
  }

  const updatePreference = async (patch) => {
    try {
      await updatePreferencesMutation.mutateAsync({
        Locale: toServerLocale(i18n.language),
        NotificationsMuted: user.NotificationsMuted,
        NotificationsSoundEnabled: user.NotificationsSoundEnabled,
        ...patch,
      })
    } catch (error) {
      toast({ variant: 'danger', title: 'Could not save preference', description: error?.message || 'Something went wrong.' })
    }
  }

  return (
    <div className="flex max-w-md flex-col gap-4">
      <h2 className="text-sm font-semibold text-fg-heading">{t('settings.preferences')}</h2>

      <LanguageSwitcher />

      <div className="flex items-center justify-between gap-3">
        <div>
          <p className="text-sm font-medium text-fg-default">{t('notifications.muteNotifications')}</p>
          <p className="text-xs text-fg-muted">{t('notifications.muteNotificationsHint')}</p>
        </div>
        <Switch
          checked={user.NotificationsMuted}
          onCheckedChange={(checked) => updatePreference({ NotificationsMuted: checked })}
          aria-label={t('notifications.muteNotifications')}
        />
      </div>

      <div className="flex items-center justify-between gap-3">
        <div>
          <p className="text-sm font-medium text-fg-default">{t('notifications.notificationSound')}</p>
          <p className="text-xs text-fg-muted">{t('notifications.notificationSoundHint')}</p>
        </div>
        <Switch
          checked={user.NotificationsSoundEnabled}
          onCheckedChange={(checked) => updatePreference({ NotificationsSoundEnabled: checked })}
          aria-label={t('notifications.notificationSound')}
        />
      </div>

      <div className="flex items-center justify-between gap-3">
        <div>
          <p className="text-sm font-medium text-fg-default">{t('desktopNotifications.title')}</p>
          <p className="text-xs text-fg-muted">{t('desktopNotifications.hint')}</p>
        </div>
        <Switch
          checked={desktopEnabled}
          onCheckedChange={handleToggleDesktop}
          aria-label={t('desktopNotifications.title')}
        />
      </div>
    </div>
  )
}
