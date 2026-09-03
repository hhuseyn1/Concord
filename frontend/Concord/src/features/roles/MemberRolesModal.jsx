import { useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { EmptyState } from '../../components/ui/EmptyState'
import { Modal } from '../../components/ui/Modal'
import { ScrollArea } from '../../components/ui/ScrollArea'
import { Skeleton } from '../../components/ui/Skeleton'
import { Switch } from '../../components/ui/Switch'
import { toast } from '../../components/ui/Toast'
import { Shield } from 'lucide-react'
import { PERMISSIONS, hasPermission } from './permissions'
import { mapAssignRoleError } from './rolesErrors'
import { useAssignRoleMutation, useCan, useMemberRoles, useRemoveRoleMutation, useRoles } from './rolesQueries'

export function MemberRolesModal({ serverId, userId, displayName, open, onOpenChange }) {
  const { t } = useTranslation()

  const { data: roles, isLoading: rolesLoading } = useRoles(open ? serverId : undefined)
  const { data: memberRoles, isLoading: memberRolesLoading } = useMemberRoles(
    open ? serverId : undefined,
    open ? userId : undefined,
  )
  const { can, isOwner, highestRolePosition } = useCan(open ? serverId : undefined)

  const assignMutation = useAssignRoleMutation(serverId)
  const removeMutation = useRemoveRoleMutation(serverId)

  const [pendingRoleId, setPendingRoleId] = useState(null)

  const assignedRoleIds = useMemo(() => new Set((memberRoles ?? []).map((role) => role.Id)), [memberRoles])
  const assignableRoles = useMemo(() => (roles ?? []).filter((role) => !role.IsDefault), [roles])

  const canManage = can('ManageRoles')
  const isLoading = rolesLoading || memberRolesLoading

  async function handleToggle(role, assign) {
    setPendingRoleId(role.Id)
    try {
      if (assign) {
        await assignMutation.mutateAsync({ userId, roleId: role.Id })
      } else {
        await removeMutation.mutateAsync({ userId, roleId: role.Id })
      }
    } catch (error) {
      toast({ variant: 'danger', title: mapAssignRoleError(error) })
    } finally {
      setPendingRoleId(null)
    }
  }

  return (
    <Modal
      open={open}
      onOpenChange={onOpenChange}
      title={t('roles.memberRoles')}
      description={t('roles.memberRolesDescription', { name: displayName })}
    >
      {isLoading && (
        <div className="flex flex-col gap-2">
          {Array.from({ length: 3 }, (_, index) => (
            <Skeleton key={index} className="h-8 w-full rounded-md" />
          ))}
        </div>
      )}

      {!isLoading && assignableRoles.length === 0 && (
        <EmptyState icon={Shield} title={t('roles.noRoles')} description={t('roles.noAssignableRolesHint')} />
      )}

      {!isLoading && assignableRoles.length > 0 && (
        <ScrollArea className="max-h-80">
          <div className="flex flex-col divide-y divide-border-default pr-2">
            {assignableRoles.map((role) => {
              const assigned = assignedRoleIds.has(role.Id)
              const outranksRole = isOwner || highestRolePosition > role.Position
              const grantsUnheldPermission =
                !isOwner && Object.keys(PERMISSIONS).some((key) => hasPermission(role.Permissions, key) && !can(key))
              const editable = canManage && outranksRole && !grantsUnheldPermission

              return (
                <div key={role.Id} className="flex items-center justify-between gap-3 py-2">
                  <div className="flex min-w-0 items-center gap-2">
                    <span
                      className="size-2.5 shrink-0 rounded-full"
                      style={{ backgroundColor: role.Color || 'currentColor' }}
                      aria-hidden="true"
                    />
                    <span className="min-w-0 truncate text-sm text-fg-default">{role.Name}</span>
                  </div>
                  <Switch
                    checked={assigned}
                    disabled={!editable || pendingRoleId === role.Id}
                    onCheckedChange={(checked) => handleToggle(role, checked)}
                  />
                </div>
              )
            })}
          </div>
        </ScrollArea>
      )}
    </Modal>
  )
}
