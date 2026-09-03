import { useTranslation } from 'react-i18next'
import { Button } from '../../components/ui/Button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuTrigger,
} from '../../components/ui/DropdownMenu'
import { Switch } from '../../components/ui/Switch'
import { toast } from '../../components/ui/Toast'
import { useAuth } from '../../hooks/useAuth'
import { BlockedTab } from '../friends/BlockedTab'
import { useUpdatePrivacyMutation } from './settingsQueries'

const FRIEND_REQUEST_OPTIONS = ['Everyone', 'FriendsOfFriends', 'Nobody']
const DIRECT_MESSAGE_OPTIONS = ['Everyone', 'FriendsOnly', 'Nobody']
const ACTIVITY_OPTIONS = ['Everyone', 'FriendsOnly', 'Nobody']

const OPTION_LABEL_KEY = {
  Everyone: 'privacy.everyone',
  FriendsOfFriends: 'privacy.friendsOfFriends',
  FriendsOnly: 'privacy.friendsOnly',
  Nobody: 'privacy.nobody',
}

function PrivacySelect({ label, value, options, onChange }) {
  const { t } = useTranslation()
  return (
    <div className="flex items-center justify-between gap-3">
      <p className="text-sm font-medium text-fg-default">{label}</p>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="secondary" size="sm">
            {t(OPTION_LABEL_KEY[value])}
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuRadioGroup value={value} onValueChange={onChange}>
            {options.map((option) => (
              <DropdownMenuRadioItem key={option} value={option}>
                {t(OPTION_LABEL_KEY[option])}
              </DropdownMenuRadioItem>
            ))}
          </DropdownMenuRadioGroup>
        </DropdownMenuContent>
      </DropdownMenu>
    </div>
  )
}

export function PrivacySettingsSection() {
  const { t } = useTranslation()
  const { user } = useAuth()
  const mutation = useUpdatePrivacyMutation()

  if (!user) return null

  const update = async (patch) => {
    try {
      await mutation.mutateAsync({
        FriendRequestPrivacy: user.FriendRequestPrivacy,
        DirectMessagePrivacy: user.DirectMessagePrivacy,
        ActivityVisibility: user.ActivityVisibility,
        ReadReceiptsEnabled: user.ReadReceiptsEnabled,
        ...patch,
      })
    } catch (error) {
      toast({ variant: 'danger', title: 'Could not save privacy settings', description: error?.message || 'Something went wrong.' })
    }
  }

  return (
    <div className="flex max-w-md flex-col gap-6">
      <div>
        <h2 className="mb-4 text-sm font-semibold text-fg-heading">{t('privacy.title')}</h2>
        <div className="flex flex-col gap-4">
          <PrivacySelect
            label={t('privacy.friendRequests')}
            value={user.FriendRequestPrivacy}
            options={FRIEND_REQUEST_OPTIONS}
            onChange={(value) => update({ FriendRequestPrivacy: value })}
          />
          <PrivacySelect
            label={t('privacy.directMessages')}
            value={user.DirectMessagePrivacy}
            options={DIRECT_MESSAGE_OPTIONS}
            onChange={(value) => update({ DirectMessagePrivacy: value })}
          />
          <PrivacySelect
            label={t('privacy.activityVisibility')}
            value={user.ActivityVisibility}
            options={ACTIVITY_OPTIONS}
            onChange={(value) => update({ ActivityVisibility: value })}
          />
          <div className="flex items-center justify-between gap-3">
            <div>
              <p className="text-sm font-medium text-fg-default">{t('privacy.readReceipts')}</p>
              <p className="text-xs text-fg-muted">{t('privacy.readReceiptsHint')}</p>
            </div>
            <Switch
              checked={user.ReadReceiptsEnabled}
              onCheckedChange={(checked) => update({ ReadReceiptsEnabled: checked })}
              aria-label={t('privacy.readReceipts')}
            />
          </div>
        </div>
      </div>

      <div className="border-t border-border-subtle pt-6">
        <h2 className="mb-4 text-sm font-semibold text-fg-heading">{t('privacy.blockedUsers')}</h2>
        <BlockedTab />
      </div>
    </div>
  )
}
