import { Check, Copy } from 'lucide-react'
import { useState } from 'react'
import { Button } from '../../components/ui/Button'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { Skeleton } from '../../components/ui/Skeleton'
import { Spinner } from '../../components/ui/Spinner'
import { toast } from '../../components/ui/Toast'
import { cn } from '../../lib/cn'
import { mapGenerateInviteError, mapListInvitesError } from './serversErrors'
import { useGenerateInviteMutation, useServerInvites } from './serversQueries'

const EXPIRY_OPTIONS = [
  { label: 'Never', ms: null },
  { label: '30 minutes', ms: 30 * 60 * 1000 },
  { label: '1 hour', ms: 60 * 60 * 1000 },
  { label: '1 day', ms: 24 * 60 * 60 * 1000 },
  { label: '7 days', ms: 7 * 24 * 60 * 60 * 1000 },
]

const selectClassName = cn(
  'h-9 w-full rounded-md border border-border-default bg-surface-sidebar px-3 text-base sm:text-sm text-fg-default',
  'outline-none focus-visible:border-brand focus-visible:ring-2 focus-visible:ring-brand',
)

function inviteUrl(code) {
  return `${window.location.origin}/cabinet?invite=${code}`
}

function describeExpiry(expiresAtUtc) {
  if (!expiresAtUtc) return 'Never expires'
  const date = new Date(expiresAtUtc)
  if (date.getTime() <= Date.now()) return 'Expired'
  return `Expires ${date.toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' })}`
}

function describeUses(maxUses, useCount) {
  if (!maxUses) return `${useCount} use${useCount === 1 ? '' : 's'}`
  const exhausted = useCount >= maxUses
  return `${useCount} / ${maxUses} uses${exhausted ? ' - exhausted' : ''}`
}

function isInviteUsable(invite) {
  const isExpired = Boolean(invite.ExpiresAtUtc) && new Date(invite.ExpiresAtUtc).getTime() <= Date.now()
  const isExhausted = Boolean(invite.MaxUses) && invite.UseCount >= invite.MaxUses
  return !isExpired && !isExhausted
}

function InviteRow({ invite }) {
  const [copied, setCopied] = useState(false)
  const isUsable = isInviteUsable(invite)

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(inviteUrl(invite.Code))
      setCopied(true)
      toast({ variant: 'success', description: 'Invite link copied to clipboard.' })
      setTimeout(() => setCopied(false), 2000)
    } catch {
      toast({ variant: 'danger', description: 'Could not copy automatically - copy the code manually.' })
    }
  }

  return (
    <div
      className={cn(
        'flex items-center gap-2 rounded-md border border-border-default bg-surface-sidebar px-3 py-2',
        !isUsable && 'opacity-60',
      )}
    >
      <div className="min-w-0 flex-1">
        <code className="block truncate font-mono text-sm text-fg-default">{invite.Code}</code>
        <p className="text-xs text-fg-muted">
          {describeUses(invite.MaxUses, invite.UseCount)} · {describeExpiry(invite.ExpiresAtUtc)}
        </p>
      </div>
      <Button size="sm" variant="secondary" onClick={handleCopy} disabled={!isUsable}>
        {copied ? <Check className="size-4" aria-hidden="true" /> : <Copy className="size-4" aria-hidden="true" />}
        {copied ? 'Copied' : 'Copy'}
      </Button>
    </div>
  )
}

export function InviteModal({ server, open, onOpenChange }) {
  const [expiryMs, setExpiryMs] = useState(EXPIRY_OPTIONS[0].ms)
  const [maxUses, setMaxUses] = useState('')
  const generateMutation = useGenerateInviteMutation(server?.Id)
  const { data: invites, isLoading, isError, error } = useServerInvites(server?.Id, { enabled: open })

  const handleGenerate = async () => {
    const parsedMaxUses = maxUses.trim() ? Number.parseInt(maxUses, 10) : null
    if (maxUses.trim() && (!Number.isFinite(parsedMaxUses) || parsedMaxUses <= 0)) {
      toast({ variant: 'danger', title: 'Could not generate invite', description: 'Max uses must be a positive number.' })
      return
    }
    try {
      await generateMutation.mutateAsync({
        ExpiresAtUtc: expiryMs ? new Date(Date.now() + expiryMs).toISOString() : null,
        MaxUses: parsedMaxUses,
      })
    } catch (error) {
      toast({ variant: 'danger', title: 'Could not generate invite', description: mapGenerateInviteError(error) })
    }
  }

  return (
    <Modal
      open={open}
      onOpenChange={onOpenChange}
      title={`Invite people to ${server?.Name || 'this server'}`}
      description="Every invite you generate is listed below - closing this doesn't lose it."
      size="sm"
    >
      <div className="flex flex-col gap-4">
        <div className="grid grid-cols-2 gap-3">
          <FormField label="Expires">
            <select
              value={expiryMs ?? ''}
              onChange={(event) => setExpiryMs(event.target.value ? Number(event.target.value) : null)}
              className={selectClassName}
            >
              {EXPIRY_OPTIONS.map((option) => (
                <option key={option.label} value={option.ms ?? ''}>
                  {option.label}
                </option>
              ))}
            </select>
          </FormField>
          <FormField label="Max uses" hint="Blank = unlimited">
            <Input
              type="number"
              min="1"
              inputMode="numeric"
              placeholder="Unlimited"
              value={maxUses}
              onChange={(event) => setMaxUses(event.target.value)}
            />
          </FormField>
        </div>

        <Button onClick={handleGenerate} disabled={generateMutation.isPending}>
          {generateMutation.isPending && <Spinner size="sm" />}
          Generate invite link
        </Button>

        <div className="flex flex-col gap-2">
          {isLoading ? (
            <>
              <Skeleton className="h-14 w-full" />
              <Skeleton className="h-14 w-full" />
            </>
          ) : isError ? (
            <p className="text-sm text-danger">{mapListInvitesError(error)}</p>
          ) : invites?.length ? (
            invites.map((invite) => <InviteRow key={invite.Code} invite={invite} />)
          ) : (
            <p className="text-sm text-fg-muted">No invites generated yet.</p>
          )}
        </div>
      </div>
    </Modal>
  )
}
