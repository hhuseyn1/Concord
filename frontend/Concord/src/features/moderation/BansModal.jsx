import { Ban } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Avatar } from '../../components/ui/Avatar'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { Modal } from '../../components/ui/Modal'
import { ScrollArea } from '../../components/ui/ScrollArea'
import { Skeleton } from '../../components/ui/Skeleton'
import { toast } from '../../components/ui/Toast'
import { mapGetBansError, mapUnbanUserError } from './moderationErrors'
import { flattenBanPages, useBans, useUnbanUserMutation } from './moderationQueries'

export function BansModal({ server, open, onOpenChange }) {
  const { t } = useTranslation()
  const serverId = server?.Id

  const { data, isLoading, isError, error, hasNextPage, isFetchingNextPage, fetchNextPage } = useBans(serverId, open)
  const unbanMutation = useUnbanUserMutation(serverId)

  const bans = flattenBanPages(data)

  async function handleUnban(ban) {
    const displayName = ban.User?.Username || t('common.unknownUser')
    try {
      await unbanMutation.mutateAsync(ban.User.Id)
      toast({ variant: 'success', title: t('moderation.unbanned', { name: displayName }) })
    } catch (unbanError) {
      toast({ variant: 'danger', title: mapUnbanUserError(unbanError) })
    }
  }

  return (
    <Modal
      open={open}
      onOpenChange={onOpenChange}
      title={t('moderation.bansTitle')}
      description={t('moderation.bansDescription', { server: server?.Name || 'Server' })}
      size="lg"
    >
      <ScrollArea className="max-h-[24rem]">
        <div className="flex flex-col gap-2 pr-2">
          {isLoading && Array.from({ length: 3 }, (_, index) => <Skeleton key={index} className="h-12 w-full rounded-md" />)}

          {isError && <EmptyState title={mapGetBansError(error)} />}

          {!isLoading && !isError && bans.length === 0 && (
            <EmptyState icon={Ban} title={t('moderation.noBansTitle')} description={t('moderation.noBansDescription')} />
          )}

          {bans.map((ban) => {
            const displayName =
              ban.User?.Username ||
              [ban.User?.Name, ban.User?.Surname].filter(Boolean).join(' ') ||
              t('common.unknownUser')

            return (
              <div
                key={ban.User?.Id}
                className="flex items-center gap-3 rounded-md border border-border-default px-3 py-2"
              >
                <Avatar src={ban.User?.AvatarUrl ?? undefined} name={displayName} size="sm" />
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium text-fg-default">{displayName}</p>
                  <p className="truncate text-xs text-fg-muted">
                    {ban.Reason || t('moderation.noReason')}
                    {ban.ExpiresAtUtc
                      ? ` · ${t('moderation.expires', { date: new Date(ban.ExpiresAtUtc).toLocaleString() })}`
                      : ` · ${t('moderation.permanent')}`}
                  </p>
                </div>
                <Button variant="secondary" size="sm" onClick={() => handleUnban(ban)} disabled={unbanMutation.isPending}>
                  {t('moderation.unban')}
                </Button>
              </div>
            )
          })}

          {hasNextPage && (
            <div className="flex justify-center">
              <Button variant="secondary" size="sm" onClick={() => fetchNextPage()} disabled={isFetchingNextPage}>
                {t('moderation.loadMore')}
              </Button>
            </div>
          )}
        </div>
      </ScrollArea>
    </Modal>
  )
}
