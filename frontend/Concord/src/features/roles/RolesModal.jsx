import { Plus, Shield, Trash2 } from 'lucide-react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { ScrollArea } from '../../components/ui/ScrollArea'
import { Skeleton } from '../../components/ui/Skeleton'
import { Switch } from '../../components/ui/Switch'
import { toast } from '../../components/ui/Toast'
import { PERMISSION_GROUPS, RESERVED_PERMISSIONS, hasPermission, togglePermission } from './permissions'
import { mapCreateRoleError, mapDeleteRoleError, mapUpdateRoleError } from './rolesErrors'
import {
  useCan,
  useCreateRoleMutation,
  useDeleteRoleMutation,
  useRoles,
  useUpdateRoleMutation,
} from './rolesQueries'

const DEFAULT_NEW_ROLE_COLOR = '#5865F2'

function PermissionRow({ permissionKey, checked, disabled, reserved, onChange }) {
  const { t } = useTranslation()

  return (
    <div className="flex items-start justify-between gap-3 py-1.5">
      <div className="min-w-0">
        <p className="text-sm text-fg-default">{t(`roles.permission.${permissionKey}`)}</p>
        <p className="text-xs text-fg-muted">
          {reserved ? t('roles.reservedHint') : t(`roles.permissionHint.${permissionKey}`)}
        </p>
      </div>
      <Switch checked={checked} disabled={disabled || reserved} onCheckedChange={onChange} />
    </div>
  )
}

export function RolesModal({ server, open, onOpenChange }) {
  const { t } = useTranslation()
  const serverId = server?.Id

  const { data: roles, isLoading } = useRoles(open ? serverId : undefined)
  const { can, isOwner, highestRolePosition } = useCan(open ? serverId : undefined)

  const createMutation = useCreateRoleMutation(serverId)
  const updateMutation = useUpdateRoleMutation(serverId)
  const deleteMutation = useDeleteRoleMutation(serverId)

  const [selectedRoleId, setSelectedRoleId] = useState(null)
  const [draft, setDraft] = useState(null)
  const [creating, setCreating] = useState(false)
  const [newRoleName, setNewRoleName] = useState('')

  const [prevOpen, setPrevOpen] = useState(open)
  if (open !== prevOpen) {
    setPrevOpen(open)
    if (open) {
      setSelectedRoleId(null)
      setDraft(null)
      setCreating(false)
      setNewRoleName('')
    }
  }

  const selectedRole = roles?.find((role) => role.Id === selectedRoleId) ?? null

  const working = draft ?? selectedRole

  const canManage = can('ManageRoles')
  const outranksSelected = isOwner || (selectedRole ? highestRolePosition > selectedRole.Position : false)
  const editable = canManage && outranksSelected

  function selectRole(role) {
    setSelectedRoleId(role.Id)
    setDraft(null)
    setCreating(false)
  }

  function togglePermissionInDraft(permissionKey, enabled) {
    setDraft((current) => {
      const base = current ?? selectedRole
      if (!base) return current
      return { ...base, Permissions: togglePermission(base.Permissions, permissionKey, enabled) }
    })
  }

  async function handleSave() {
    if (!draft) return
    try {
      await updateMutation.mutateAsync({
        roleId: draft.Id,
        Name: draft.Name,
        Color: draft.Color,
        Permissions: draft.Permissions,
      })
      setDraft(null)
      toast({ variant: 'success', title: t('roles.saved') })
    } catch (error) {
      toast({ variant: 'danger', title: mapUpdateRoleError(error) })
    }
  }

  async function handleCreate() {
    const name = newRoleName.trim()
    if (!name) return
    try {
      const role = await createMutation.mutateAsync({ Name: name, Color: DEFAULT_NEW_ROLE_COLOR, Permissions: 0 })
      setCreating(false)
      setNewRoleName('')
      setSelectedRoleId(role.Id)
      toast({ variant: 'success', title: t('roles.created') })
    } catch (error) {
      toast({ variant: 'danger', title: mapCreateRoleError(error) })
    }
  }

  async function handleDelete(role) {
    try {
      await deleteMutation.mutateAsync(role.Id)
      if (selectedRoleId === role.Id) {
        setSelectedRoleId(null)
        setDraft(null)
      }
      toast({ variant: 'success', title: t('roles.deleted') })
    } catch (error) {
      toast({ variant: 'danger', title: mapDeleteRoleError(error) })
    }
  }

  return (
    <Modal
      open={open}
      onOpenChange={onOpenChange}
      title={t('roles.title')}
      description={t('roles.subtitle', { server: server?.Name || 'Server' })}
      size="xl"
    >
      <div className="flex min-h-[22rem] gap-4">
        <div className="flex w-52 shrink-0 flex-col gap-2 border-r border-border-default pr-4">
          {canManage && !creating && (
            <Button variant="secondary" size="sm" onClick={() => setCreating(true)}>
              <Plus className="size-4" aria-hidden="true" />
              {t('roles.newRole')}
            </Button>
          )}

          {creating && (
            <div className="flex flex-col gap-2">
              <Input
                value={newRoleName}
                onChange={(event) => setNewRoleName(event.target.value)}
                placeholder={t('roles.namePlaceholder')}
                aria-label={t('roles.name')}
              />
              <div className="flex gap-2">
                <Button size="sm" onClick={handleCreate} disabled={createMutation.isPending || !newRoleName.trim()}>
                  {t('common.create')}
                </Button>
                <Button size="sm" variant="ghost" onClick={() => setCreating(false)}>
                  {t('common.cancel')}
                </Button>
              </div>
            </div>
          )}

          <ScrollArea className="min-h-0 flex-1">
            <div className="flex flex-col gap-1 pr-2">
              {isLoading &&
                Array.from({ length: 3 }, (_, index) => <Skeleton key={index} className="h-8 w-full rounded-md" />)}

              {roles?.map((role) => (
                <button
                  key={role.Id}
                  type="button"
                  onClick={() => selectRole(role)}
                  className={`flex items-center gap-2 rounded-md px-2 py-1.5 text-left text-sm transition-colors duration-150 ${
                    role.Id === selectedRoleId
                      ? 'bg-fg-default/10 text-fg-default'
                      : 'text-fg-muted hover:bg-fg-default/5 hover:text-fg-default'
                  }`}
                >
                  <span
                    className="size-2.5 shrink-0 rounded-full"
                    style={{ backgroundColor: role.Color || 'currentColor' }}
                    aria-hidden="true"
                  />
                  <span className="min-w-0 flex-1 truncate">{role.Name}</span>
                  <span className="text-xs text-fg-muted">{role.MemberCount}</span>
                </button>
              ))}
            </div>
          </ScrollArea>
        </div>

        <div className="min-w-0 flex-1">
          {!working && (
            <EmptyState
              icon={Shield}
              title={t('roles.noSelectionTitle')}
              description={t('roles.noSelectionDescription')}
            />
          )}

          {working && (
            <div className="flex h-full flex-col">
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0 flex-1">
                  {working.IsDefault ? (
                    <>
                      <p className="text-sm font-medium text-fg-default">{working.Name}</p>
                      <p className="text-xs text-fg-muted">{t('roles.defaultRoleHint')}</p>
                    </>
                  ) : (
                    <FormField label={t('roles.name')}>
                      <Input
                        value={working.Name ?? ''}
                        disabled={!editable}
                        onChange={(event) =>
                          setDraft((current) => ({ ...(current ?? selectedRole), Name: event.target.value }))
                        }
                      />
                    </FormField>
                  )}
                </div>

                {!working.IsDefault && editable && (
                  <Button
                    variant="danger"
                    size="sm"
                    onClick={() => handleDelete(working)}
                    disabled={deleteMutation.isPending}
                  >
                    <Trash2 className="size-4" aria-hidden="true" />
                    {t('common.delete')}
                  </Button>
                )}
              </div>

              {!editable && (
                <p className="mt-2 rounded-md bg-fg-default/5 px-3 py-2 text-xs text-fg-muted">
                  {canManage ? t('roles.outrankedHint') : t('roles.readOnlyHint')}
                </p>
              )}

              <ScrollArea className="mt-3 min-h-0 flex-1">
                <div className="flex flex-col gap-4 pr-2">
                  {PERMISSION_GROUPS.map((group) => (
                    <div key={group.id}>
                      <p className="mb-1 text-xs font-semibold tracking-wide text-fg-muted uppercase">
                        {t(`roles.group.${group.id}`)}
                      </p>
                      <div className="divide-y divide-border-default">
                        {group.keys.map((permissionKey) => (
                          <PermissionRow
                            key={permissionKey}
                            permissionKey={permissionKey}
                            checked={hasPermission(working.Permissions, permissionKey)}
                            disabled={!editable || (!isOwner && !can(permissionKey))}
                            reserved={RESERVED_PERMISSIONS.includes(permissionKey)}
                            onChange={(enabled) => togglePermissionInDraft(permissionKey, enabled)}
                          />
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              </ScrollArea>

              {draft && (
                <div className="mt-3 flex justify-end gap-2 border-t border-border-default pt-3">
                  <Button variant="ghost" size="sm" onClick={() => setDraft(null)}>
                    {t('common.cancel')}
                  </Button>
                  <Button size="sm" onClick={handleSave} disabled={updateMutation.isPending}>
                    {t('common.save')}
                  </Button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </Modal>
  )
}
