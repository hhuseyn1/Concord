import { ChevronLeft, ChevronRight, ShieldOff, Users } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Avatar } from '../../components/ui/Avatar'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { Input } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { Skeleton } from '../../components/ui/Skeleton'
import { toast } from '../../components/ui/Toast'
import { useAuth } from '../../hooks/useAuth'
import { mapAdminLoadError, mapDisableUserError, mapEnableUserError, mapSetUserRoleError } from './adminErrors'
import { useAdminUsers, useDisableUserMutation, useEnableUserMutation, useSetUserRoleMutation } from './adminQueries'

const SEARCH_DEBOUNCE_MS = 300

function DisableConfirmModal({ user, open, onOpenChange, onConfirm, pending }) {
  const { t } = useTranslation()
  const displayName = user?.Username || [user?.Name, user?.Surname].filter(Boolean).join(' ') || t('common.unknownUser')

  return (
    <Modal
      open={open}
      onOpenChange={onOpenChange}
      title={t('admin.disableTitle', { name: displayName })}
      description={t('admin.disableDescription')}
      footer={
        <>
          <Button variant="ghost" onClick={() => onOpenChange(false)}>
            {t('common.cancel')}
          </Button>
          <Button variant="danger" onClick={onConfirm} disabled={pending}>
            {t('admin.disable')}
          </Button>
        </>
      }
    />
  )
}

export function AdminUsersTable() {
  const { t } = useTranslation()
  const { user: currentUser } = useAuth()

  const [searchInput, setSearchInput] = useState('')
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)
  const [disableTarget, setDisableTarget] = useState(null)

  useEffect(() => {
    const handle = setTimeout(() => {
      setSearch(searchInput.trim())
      setPage(1)
    }, SEARCH_DEBOUNCE_MS)
    return () => clearTimeout(handle)
  }, [searchInput])

  const { data, isLoading, isFetching, isError, error } = useAdminUsers(page, search)
  const disableMutation = useDisableUserMutation()
  const enableMutation = useEnableUserMutation()
  const setRoleMutation = useSetUserRoleMutation()

  const users = data?.Items ?? []
  const totalCount = data?.TotalCount ?? 0
  const pageSize = data?.PageSize ?? 20
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize))

  async function handleConfirmDisable() {
    if (!disableTarget) return
    try {
      await disableMutation.mutateAsync(disableTarget.Id)
      toast({ variant: 'success', title: t('admin.userDisabled') })
      setDisableTarget(null)
    } catch (disableError) {
      toast({ variant: 'danger', title: mapDisableUserError(disableError) })
    }
  }

  async function handleEnable(targetUser) {
    try {
      await enableMutation.mutateAsync(targetUser.Id)
      toast({ variant: 'success', title: t('admin.userEnabled') })
    } catch (enableError) {
      toast({ variant: 'danger', title: mapEnableUserError(enableError) })
    }
  }

  async function handleToggleRole(targetUser) {
    const nextRole = targetUser.Role === 'Admin' ? 'User' : 'Admin'
    try {
      await setRoleMutation.mutateAsync({ userId: targetUser.Id, role: nextRole })
      toast({
        variant: 'success',
        title: t(nextRole === 'Admin' ? 'admin.promoted' : 'admin.demoted', { name: targetUser.Username }),
      })
    } catch (roleError) {
      toast({ variant: 'danger', title: mapSetUserRoleError(roleError) })
    }
  }

  return (
    <div className="flex flex-col gap-3">
      <Input
        value={searchInput}
        onChange={(event) => setSearchInput(event.target.value)}
        placeholder={t('admin.searchPlaceholder')}
        className="max-w-xs"
        aria-label={t('admin.searchPlaceholder')}
      />

      {isLoading && (
        <div className="flex flex-col gap-2">
          {Array.from({ length: 6 }, (_, index) => (
            <Skeleton key={index} className="h-12 w-full rounded-md" />
          ))}
        </div>
      )}

      {isError && <EmptyState title={t('admin.usersLoadFailed')} description={mapAdminLoadError(error)} />}

      {!isLoading && !isError && users.length === 0 && (
        <EmptyState icon={Users} title={t('admin.noUsersTitle')} description={t('admin.noUsersDescription')} />
      )}

      {!isLoading && !isError && users.length > 0 && (
        <div className="overflow-x-auto rounded-md border border-border-default">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-border-default bg-surface-sidebar text-xs text-fg-muted uppercase">
              <tr>
                <th className="px-3 py-2 font-semibold">{t('admin.columnUser')}</th>
                <th className="px-3 py-2 font-semibold">{t('admin.columnEmail')}</th>
                <th className="px-3 py-2 font-semibold">{t('admin.columnRole')}</th>
                <th className="px-3 py-2 font-semibold">{t('admin.columnStatus')}</th>
                <th className="px-3 py-2 font-semibold">{t('admin.columnActions')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-default">
              {users.map((row) => {
                const displayName = row.Username || [row.Name, row.Surname].filter(Boolean).join(' ') || t('common.unknownUser')
                const isSelf = row.Id === currentUser?.Id

                return (
                  <tr key={row.Id}>
                    <td className="px-3 py-2">
                      <div className="flex items-center gap-2">
                        <Avatar src={row.AvatarUrl ?? undefined} name={displayName} size="sm" />
                        <span className="font-medium text-fg-default">{displayName}</span>
                      </div>
                    </td>
                    <td className="px-3 py-2 text-fg-muted">{row.Email}</td>
                    <td className="px-3 py-2">
                      <Badge variant={row.Role === 'Admin' ? 'brand' : 'neutral'}>{row.Role}</Badge>
                    </td>
                    <td className="px-3 py-2">
                      <div className="flex flex-wrap gap-1">
                        {row.Disabled && <Badge variant="danger">{t('admin.statusDisabled')}</Badge>}
                        {row.LockedOut && <Badge variant="warning">{t('admin.statusLockedOut')}</Badge>}
                        {row.TwoFactorEnabled && <Badge variant="success">{t('admin.status2fa')}</Badge>}
                        {!row.Disabled && !row.LockedOut && <Badge variant="neutral">{t('admin.statusActive')}</Badge>}
                      </div>
                    </td>
                    <td className="px-3 py-2">
                      <div className="flex flex-wrap gap-2">
                        <Button
                          size="sm"
                          variant="ghost"
                          disabled={isSelf || setRoleMutation.isPending}
                          onClick={() => handleToggleRole(row)}
                        >
                          {row.Role === 'Admin' ? t('admin.demote') : t('admin.promote')}
                        </Button>
                        {row.Disabled ? (
                          <Button size="sm" variant="secondary" disabled={enableMutation.isPending} onClick={() => handleEnable(row)}>
                            {t('admin.enable')}
                          </Button>
                        ) : (
                          <Button
                            size="sm"
                            variant="danger"
                            disabled={isSelf}
                            onClick={() => setDisableTarget(row)}
                            title={isSelf ? t('admin.cannotDisableSelf') : undefined}
                          >
                            <ShieldOff className="size-3.5" aria-hidden="true" />
                            {t('admin.disable')}
                          </Button>
                        )}
                      </div>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      )}

      {!isLoading && !isError && totalCount > 0 && (
        <div className="flex items-center justify-between text-sm text-fg-muted">
          <span>{t('admin.pageSummary', { page, totalPages, total: totalCount })}</span>
          <div className="flex gap-2">
            <Button
              size="sm"
              variant="secondary"
              disabled={page <= 1 || isFetching}
              onClick={() => setPage((current) => Math.max(1, current - 1))}
            >
              <ChevronLeft className="size-4" aria-hidden="true" />
              {t('admin.previous')}
            </Button>
            <Button
              size="sm"
              variant="secondary"
              disabled={page >= totalPages || isFetching}
              onClick={() => setPage((current) => current + 1)}
            >
              {t('admin.next')}
              <ChevronRight className="size-4" aria-hidden="true" />
            </Button>
          </div>
        </div>
      )}

      <DisableConfirmModal
        user={disableTarget}
        open={Boolean(disableTarget)}
        onOpenChange={(open) => !open && setDisableTarget(null)}
        onConfirm={handleConfirmDisable}
        pending={disableMutation.isPending}
      />
    </div>
  )
}
