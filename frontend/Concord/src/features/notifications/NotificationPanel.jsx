import { CheckCheck, Inbox } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { ScrollArea } from '../../components/ui/ScrollArea'
import { Skeleton } from '../../components/ui/Skeleton'
import { toast } from '../../components/ui/Toast'
import { NotificationRow } from './NotificationRow'
import {
  flattenNotificationPages,
  useMarkAllNotificationsReadMutation,
  useNotificationsList,
} from './notificationsQueries'

function RowSkeletons() {
  return (
    <div className="flex flex-col gap-1 p-2">
      {Array.from({ length: 3 }, (_, index) => (
        <div key={index} className="flex items-start gap-3 px-3 py-2">
          <Skeleton className="size-10 rounded-full" />
          <div className="flex flex-1 flex-col gap-1.5">
            <Skeleton className="h-3.5 w-40" />
            <Skeleton className="h-3 w-16" />
          </div>
        </div>
      ))}
    </div>
  )
}

export function NotificationPanel({ onNavigate }) {
  const { t } = useTranslation()
  const { data, isLoading, isError, error, refetch, fetchNextPage, hasNextPage, isFetchingNextPage } =
    useNotificationsList()
  const markAllMutation = useMarkAllNotificationsReadMutation()

  const notifications = flattenNotificationPages(data?.pages)
  const hasUnread = notifications.some((item) => !item.IsRead)

  const handleMarkAll = async () => {
    try {
      await markAllMutation.mutateAsync()
    } catch (markAllError) {
      toast({
        variant: 'danger',
        title: 'Could not mark all as read',
        description: markAllError?.message || 'Something went wrong.',
      })
    }
  }

  return (
    <div data-testid="notification-panel" className="flex max-h-[28rem] w-80 flex-col">
      <div className="flex shrink-0 items-center justify-between border-b border-border-subtle px-4 py-3">
        <p className="text-sm font-semibold text-fg-heading">{t('notifications.title')}</p>
        <Button size="sm" variant="ghost" disabled={!hasUnread || markAllMutation.isPending} onClick={handleMarkAll}>
          <CheckCheck className="size-4" aria-hidden="true" />
          Mark all read
        </Button>
      </div>

      {isLoading ? (
        <RowSkeletons />
      ) : isError ? (
        <div className="p-4">
          <EmptyState
            title="Couldn't load notifications"
            description={error?.message || 'Something went wrong.'}
            action={
              <Button variant="secondary" size="sm" onClick={() => refetch()}>
                Try again
              </Button>
            }
          />
        </div>
      ) : notifications.length === 0 ? (
        <div className="p-4">
          <EmptyState
            icon={Inbox}
            title="No notifications yet"
            description="Friend request activity will show up here."
          />
        </div>
      ) : (
        <ScrollArea className="min-h-0 flex-1">
          <div className="flex flex-col gap-0.5 p-2">
            {notifications.map((notification) => (
              <NotificationRow key={notification.Id} notification={notification} onNavigate={onNavigate} />
            ))}
          </div>
          {hasNextPage && (
            <div className="p-2">
              <Button
                variant="secondary"
                size="sm"
                className="w-full"
                disabled={isFetchingNextPage}
                onClick={() => fetchNextPage()}
              >
                {isFetchingNextPage ? 'Loading…' : 'Load more'}
              </Button>
            </div>
          )}
        </ScrollArea>
      )}
    </div>
  )
}
