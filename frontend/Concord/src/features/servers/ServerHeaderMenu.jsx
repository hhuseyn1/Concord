import { Ban, ChevronDown, LogOut, Settings, Shield, Ticket, Trash2, UserCog } from 'lucide-react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '../../components/ui/DropdownMenu'
import { IconButton } from '../../components/ui/IconButton'
import { Tooltip } from '../../components/ui/Tooltip'
import { BansModal } from '../moderation/BansModal'
import { RolesModal } from '../roles/RolesModal'
import { useCan } from '../roles/rolesQueries'
import { DeleteServerModal } from './DeleteServerModal'
import { EditServerModal } from './EditServerModal'
import { InviteModal } from './InviteModal'
import { LeaveServerModal } from './LeaveServerModal'
import { TransferOwnershipModal } from './TransferOwnershipModal'

export function ServerHeaderMenu({ server, isOwner }) {
  const { t } = useTranslation()
  const [inviteOpen, setInviteOpen] = useState(false)
  const [transferOpen, setTransferOpen] = useState(false)
  const [leaveOpen, setLeaveOpen] = useState(false)
  const [deleteOpen, setDeleteOpen] = useState(false)
  const [editOpen, setEditOpen] = useState(false)
  const [rolesOpen, setRolesOpen] = useState(false)
  const [bansOpen, setBansOpen] = useState(false)

  const { can } = useCan(server?.Id)

  const canInvite = can('ManageInvites')
  const canEditServer = can('ManageServer')
  const canManageRoles = can('ManageRoles')
  const canBanMembers = can('BanMembers')

  return (
    <>
      <DropdownMenu>
        <Tooltip content="Server options">
          <DropdownMenuTrigger asChild>
            <IconButton aria-label="Server options" variant="ghost" size="sm">
              <ChevronDown className="size-4" aria-hidden="true" />
            </IconButton>
          </DropdownMenuTrigger>
        </Tooltip>
        <DropdownMenuContent align="start">
          <DropdownMenuLabel>{server?.Name || 'Server'}</DropdownMenuLabel>
          <DropdownMenuSeparator />

          {canInvite && (
            <DropdownMenuItem onSelect={() => setInviteOpen(true)}>
              <Ticket className="size-4" aria-hidden="true" />
              Invite People
            </DropdownMenuItem>
          )}

          {canEditServer && (
            <DropdownMenuItem onSelect={() => setEditOpen(true)}>
              <Settings className="size-4" aria-hidden="true" />
              Edit Server
            </DropdownMenuItem>
          )}

          {canManageRoles && (
            <DropdownMenuItem onSelect={() => setRolesOpen(true)}>
              <Shield className="size-4" aria-hidden="true" />
              {t('roles.manageRoles')}
            </DropdownMenuItem>
          )}

          {canBanMembers && (
            <DropdownMenuItem onSelect={() => setBansOpen(true)}>
              <Ban className="size-4" aria-hidden="true" />
              {t('moderation.bansTitle')}
            </DropdownMenuItem>
          )}

          {isOwner && (
            <DropdownMenuItem onSelect={() => setTransferOpen(true)}>
              <UserCog className="size-4" aria-hidden="true" />
              Transfer Ownership
            </DropdownMenuItem>
          )}

          {isOwner ? (
            <DropdownMenuItem disabled className="flex-col items-start gap-0.5 whitespace-normal">
              <span className="flex items-center gap-2">
                <LogOut className="size-4" aria-hidden="true" />
                Leave Server
              </span>
              <span className="pl-6 text-xs font-normal text-fg-muted">
                Transfer ownership first - owners can't leave their own server.
              </span>
            </DropdownMenuItem>
          ) : (
            <DropdownMenuItem danger onSelect={() => setLeaveOpen(true)}>
              <LogOut className="size-4" aria-hidden="true" />
              Leave Server
            </DropdownMenuItem>
          )}

          {isOwner && (
            <>
              <DropdownMenuSeparator />
              <DropdownMenuItem danger onSelect={() => setDeleteOpen(true)}>
                <Trash2 className="size-4" aria-hidden="true" />
                Delete Server
              </DropdownMenuItem>
            </>
          )}
        </DropdownMenuContent>
      </DropdownMenu>

      {canEditServer && <EditServerModal server={server} open={editOpen} onOpenChange={setEditOpen} />}
      {canInvite && <InviteModal server={server} open={inviteOpen} onOpenChange={setInviteOpen} />}
      {canManageRoles && <RolesModal server={server} open={rolesOpen} onOpenChange={setRolesOpen} />}
      {canBanMembers && <BansModal server={server} open={bansOpen} onOpenChange={setBansOpen} />}
      {isOwner && <TransferOwnershipModal server={server} open={transferOpen} onOpenChange={setTransferOpen} />}
      {!isOwner && <LeaveServerModal server={server} open={leaveOpen} onOpenChange={setLeaveOpen} />}
      {isOwner && <DeleteServerModal server={server} open={deleteOpen} onOpenChange={setDeleteOpen} />}
    </>
  )
}
