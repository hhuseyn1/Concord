import { ShieldOff, Users } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Avatar } from '../../components/ui/Avatar'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { DataTable } from '../../components/ui/DataTable'
import { Input } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
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

  const columns = [
    {
      key: 'user',
      header: t('admin.columnUser'),
      render: (row) => {
        const displayName = row.Username || [row.Name, row.Surname].filter(Boolean).join(' ') || t('common.unknownUser')
        return (
          <div className="flex items-center gap-2">
            <Avatar src={row.AvatarUrl ?? undefined} name={displayName} size="sm" />
            <span className="font-medium text-fg-default">{displayName}</span>
          </div>
        )
      },
    },
    {
      key: 'email',
      header: t('admin.columnEmail'),
      cellClassName: 'px-3 py-2 text-fg-muted',
      render: (row) => row.Email,
    },
    {
      key: 'role',
      header: t('admin.columnRole'),
      render: (row) => <Badge variant={row.Role === 'Admin' ? 'brand' : 'neutral'}>{row.Role}</Badge>,
    },
    {
      key: 'status',
      header: t('admin.columnStatus'),
      render: (row) => (
        <div className="flex flex-wrap gap-1">
          {row.Disabled && <Badge variant="danger">{t('admin.statusDisabled')}</Badge>}
          {row.LockedOut && <Badge variant="warning">{t('admin.statusLockedOut')}</Badge>}
          {row.TwoFactorEnabled && <Badge variant="success">{t('admin.status2fa')}</Badge>}
          {!row.Disabled && !row.LockedOut && <Badge variant="neutral">{t('admin.statusActive')}</Badge>}
        </div>
      ),
    },
    {
      key: 'actions',
      header: t('admin.columnActions'),
      render: (row) => {
        const isSelf = row.Id === currentUser?.Id
        return (
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
        )
      },
    },
  ]

  return (
    <div className="flex flex-col gap-3">
      <Input
        value={searchInput}
        onChange={(event) => setSearchInput(event.target.value)}
        placeholder={t('admin.searchPlaceholder')}
        className="max-w-xs"
        aria-label={t('admin.searchPlaceholder')}
      />

      <DataTable
        columns={columns}
        rows={users}
        loading={isLoading}
        error={isError}
        errorTitle={t('admin.usersLoadFailed')}
        errorDescription={mapAdminLoadError(error)}
        emptyIcon={Users}
        emptyTitle={t('admin.noUsersTitle')}
        emptyDescription={t('admin.noUsersDescription')}
        page={page}
        totalPages={totalPages}
        totalCount={totalCount}
        isFetching={isFetching}
        onPageChange={setPage}
      />

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
