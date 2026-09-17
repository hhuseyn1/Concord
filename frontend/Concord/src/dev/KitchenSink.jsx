import {
  Bell,
  ChevronDown,
  Inbox,
  Plus,
  Settings,
  Trash2,
  Users,
} from 'lucide-react'
import { useState } from 'react'
import { Avatar } from '../components/ui/Avatar'
import { Badge } from '../components/ui/Badge'
import { Button } from '../components/ui/Button'
import {
  ContextMenu,
  ContextMenuContent,
  ContextMenuItem,
  ContextMenuLabel,
  ContextMenuSeparator,
  ContextMenuTrigger,
} from '../components/ui/ContextMenu'
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '../components/ui/DropdownMenu'
import { EmptyState } from '../components/ui/EmptyState'
import { FormField } from '../components/ui/FormField'
import { IconButton } from '../components/ui/IconButton'
import { Input } from '../components/ui/Input'
import { Modal } from '../components/ui/Modal'
import { Popover, PopoverContent, PopoverTrigger } from '../components/ui/Popover'
import { ScrollArea } from '../components/ui/ScrollArea'
import { Skeleton } from '../components/ui/Skeleton'
import { Spinner } from '../components/ui/Spinner'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../components/ui/Tabs'
import { Textarea } from '../components/ui/Textarea'
import { toast } from '../components/ui/Toast'
import { Tooltip } from '../components/ui/Tooltip'

function Section({ title, description, children }) {
  return (
    <section className="flex flex-col gap-4 rounded-lg border border-border-default bg-surface-sidebar p-6">
      <div className="flex flex-col gap-1">
        <h2 className="text-xl font-semibold text-fg-heading">{title}</h2>
        {description && <p className="text-sm text-fg-muted">{description}</p>}
      </div>
      {children}
    </section>
  )
}

function Swatch({ name, className }) {
  return (
    <div className="flex flex-col gap-1.5">
      <div className={`h-14 w-full rounded-md border border-border-default ${className}`} />
      <span className="text-xs text-fg-muted">{name}</span>
    </div>
  )
}

const BUTTON_VARIANTS = ['primary', 'secondary', 'ghost', 'danger', 'link']
const BUTTON_SIZES = ['sm', 'md', 'lg']

export function KitchenSink() {
  const [modalOpen, setModalOpen] = useState(false)
  const [notifyChecked, setNotifyChecked] = useState(true)
  const [soundChecked, setSoundChecked] = useState(false)
  const [status, setStatus] = useState('online')
  const [formError, setFormError] = useState('')

  return (
    <div className="mx-auto flex max-w-5xl flex-col gap-8 px-6 py-10">
      <header className="flex flex-col gap-1">
        <h1 className="text-2xl font-semibold text-fg-heading">Concord - Kitchen sink</h1>
        <p className="text-sm text-fg-muted">
          Dev-only visual reference for Phase 0 design tokens and UI primitives. Not linked from
          any real navigation.
        </p>
      </header>

      <Section
        title="Surfaces & elevation"
        description="Rail → sidebar → base → floating (elevation flips direction between themes) + the recessed input well."
      >
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-5">
          <Swatch name="surface-rail" className="bg-surface-rail" />
          <Swatch name="surface-sidebar" className="bg-surface-sidebar" />
          <Swatch name="surface-base" className="bg-surface-base" />
          <Swatch name="surface-floating (shadow-lg)" className="bg-surface-floating shadow-lg" />
          <Swatch name="surface-input" className="bg-surface-input" />
        </div>
      </Section>

      <Section title="Text & brand colors">
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
          <Swatch name="fg-default" className="bg-fg-default" />
          <Swatch name="fg-muted" className="bg-fg-muted" />
          <Swatch name="fg-faint" className="bg-fg-faint" />
          <Swatch name="fg-link" className="bg-fg-link" />
          <Swatch name="fg-heading" className="bg-fg-heading" />
          <Swatch name="brand" className="bg-brand" />
          <Swatch name="brand-hover" className="bg-brand-hover" />
          <Swatch name="brand-pressed" className="bg-brand-pressed" />
          <Swatch name="brand-bg" className="bg-brand-bg" />
          <Swatch name="accent" className="bg-accent" />
        </div>
      </Section>

      <Section title="Semantic colors" description="Solid tone + background tint per status, for badges/banners.">
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
          <Swatch name="danger / danger-bg" className="bg-danger-bg border-danger" />
          <Swatch name="success / success-bg" className="bg-success-bg border-success" />
          <Swatch name="warning / warning-bg" className="bg-warning-bg border-warning" />
          <Swatch name="info / info-bg" className="bg-info-bg border-info" />
        </div>
      </Section>

      <Section title="Presence status" description="Matches the backend PresenceStatus enum exactly: Online / Idle / Offline.">
        <div className="flex items-center gap-6">
          <Avatar name="Ada Lovelace" presence="online" />
          <Avatar name="Grace Hopper" presence="idle" />
          <Avatar name="Alan Turing" presence="offline" />
        </div>
      </Section>

      <Section title="Typography" description="Message body vs. timestamps/metadata vs. headings.">
        <div className="flex flex-col gap-3">
          <p className="text-2xl font-semibold text-fg-heading">Heading 2xl / semibold</p>
          <p className="text-xl font-semibold text-fg-heading">Heading xl / semibold</p>
          <p className="text-base text-fg-default">
            Message body text (text-base) - the size used for chat message content, optimized for
            long-form readability.
          </p>
          <p className="text-sm text-fg-muted">Secondary text (text-sm, fg-muted)</p>
          <p className="text-xs text-fg-faint">Timestamp / least-important metadata (text-xs, fg-faint) - Today at 14:32</p>
          <p className="text-2xs text-fg-faint">Extra-small metadata (text-2xs, fg-faint)</p>
        </div>
      </Section>

      <Section title="Spacing, radii & shadows">
        <div className="flex flex-wrap items-end gap-4">
          {[1, 2, 3, 4, 6, 8, 12].map((step) => (
            <div key={step} className="flex flex-col items-center gap-1">
              <div className="bg-brand" style={{ width: `calc(var(--spacing) * ${step})`, height: `calc(var(--spacing) * ${step})` }} />
              <span className="text-2xs text-fg-muted">{step}</span>
            </div>
          ))}
        </div>
        <div className="flex flex-wrap gap-4">
          <div className="size-16 rounded-sm bg-surface-floating shadow-sm flex items-center justify-center text-2xs text-fg-muted">sm</div>
          <div className="size-16 rounded-md bg-surface-floating shadow-md flex items-center justify-center text-2xs text-fg-muted">md</div>
          <div className="size-16 rounded-lg bg-surface-floating shadow-lg flex items-center justify-center text-2xs text-fg-muted">lg</div>
          <div className="size-16 rounded-full bg-surface-floating shadow-md flex items-center justify-center text-2xs text-fg-muted">full</div>
        </div>
      </Section>

      <Section title="Button" description="Variants × sizes, plus disabled state.">
        <div className="flex flex-col gap-3">
          {BUTTON_VARIANTS.map((variant) => (
            <div key={variant} className="flex flex-wrap items-center gap-3">
              <span className="w-20 text-xs text-fg-muted">{variant}</span>
              {BUTTON_SIZES.map((size) => (
                <Button key={size} variant={variant} size={size}>
                  {variant} {size}
                </Button>
              ))}
              <Button variant={variant} disabled>
                disabled
              </Button>
            </div>
          ))}
        </div>
      </Section>

      <Section title="IconButton">
        <div className="flex items-center gap-3">
          <IconButton aria-label="Notifications" variant="ghost">
            <Bell className="size-4" />
          </IconButton>
          <IconButton aria-label="Add" variant="secondary">
            <Plus className="size-4" />
          </IconButton>
          <IconButton aria-label="Settings" variant="primary">
            <Settings className="size-4" />
          </IconButton>
          <IconButton aria-label="Delete" variant="danger">
            <Trash2 className="size-4" />
          </IconButton>
          <IconButton aria-label="Disabled" variant="ghost" disabled>
            <Bell className="size-4" />
          </IconButton>
        </div>
      </Section>

      <Section title="Input & Textarea">
        <div className="grid gap-4 sm:grid-cols-2">
          <Input placeholder="Regular input" />
          <Input placeholder="Disabled input" disabled />
          <Input placeholder="Invalid input" invalid defaultValue="not-an-email" />
          <Textarea placeholder="Textarea" />
        </div>
      </Section>

      <Section title="FormField" description="Label + error wrapper; generic API for future react-hook-form usage.">
        <div className="grid gap-4 sm:grid-cols-2">
          <FormField label="Username" hint="1-32 characters, letters/numbers/underscore only.">
            <Input placeholder="ada.lovelace" />
          </FormField>
          <FormField
            label="Email"
            required
            error={formError}
          >
            <Input
              placeholder="you@example.com"
              onChange={(event) =>
                setFormError(event.target.value.includes('@') ? '' : 'Enter a valid email address.')
              }
            />
          </FormField>
        </div>
      </Section>

      <Section title="Avatar">
        <div className="flex flex-wrap items-end gap-4">
          <Avatar name="Concord User" size="sm" />
          <Avatar name="Concord User" size="md" presence="online" />
          <Avatar name="Concord User" size="lg" presence="idle" />
          <Avatar name="Concord User" size="xl" presence="offline" />
          <Avatar src="https://i.pravatar.cc/128?img=12" alt="Photo avatar" name="Photo Avatar" size="lg" presence="online" />
        </div>
      </Section>

      <Section title="Badge">
        <div className="flex flex-wrap gap-2">
          <Badge variant="neutral">Neutral</Badge>
          <Badge variant="brand">Brand</Badge>
          <Badge variant="danger">Danger</Badge>
          <Badge variant="success">Success</Badge>
          <Badge variant="warning">Warning</Badge>
          <Badge variant="info">Info</Badge>
        </div>
      </Section>

      <Section title="Tooltip">
        <div className="flex gap-3">
          <Tooltip content="Mute this channel">
            <Button variant="secondary">Hover me</Button>
          </Tooltip>
          <Tooltip content="Icon-only actions need tooltips for discoverability" side="right">
            <IconButton aria-label="More info" variant="ghost">
              <Users className="size-4" />
            </IconButton>
          </Tooltip>
        </div>
      </Section>

      <Section title="Modal">
        <Modal
          open={modalOpen}
          onOpenChange={setModalOpen}
          trigger={<Button variant="primary">Open modal</Button>}
          title="Leave server?"
          description="You won't be able to rejoin unless you're invited again."
          footer={
            <>
              <Button variant="ghost" onClick={() => setModalOpen(false)}>
                Cancel
              </Button>
              <Button
                variant="danger"
                onClick={() => {
                  setModalOpen(false)
                  toast({ title: 'Left server', variant: 'success' })
                }}
              >
                Leave server
              </Button>
            </>
          }
        >
          <p className="text-sm text-fg-muted">This action cannot be undone.</p>
        </Modal>
      </Section>

      <Section title="DropdownMenu">
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="secondary">
              Server options <ChevronDown className="size-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="start">
            <DropdownMenuLabel>Notifications</DropdownMenuLabel>
            <DropdownMenuCheckboxItem checked={notifyChecked} onCheckedChange={setNotifyChecked}>
              Enable notifications
            </DropdownMenuCheckboxItem>
            <DropdownMenuCheckboxItem checked={soundChecked} onCheckedChange={setSoundChecked}>
              Play sound
            </DropdownMenuCheckboxItem>
            <DropdownMenuSeparator />
            <DropdownMenuLabel>Status</DropdownMenuLabel>
            <DropdownMenuRadioGroup value={status} onValueChange={setStatus}>
              <DropdownMenuRadioItem value="online">Online</DropdownMenuRadioItem>
              <DropdownMenuRadioItem value="idle">Idle</DropdownMenuRadioItem>
            </DropdownMenuRadioGroup>
            <DropdownMenuSeparator />
            <DropdownMenuItem danger>Leave server</DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </Section>

      <Section title="ContextMenu">
        <ContextMenu>
          <ContextMenuTrigger className="flex h-24 items-center justify-center rounded-md border border-dashed border-border-default text-sm text-fg-muted">
            Right-click this box
          </ContextMenuTrigger>
          <ContextMenuContent>
            <ContextMenuLabel># general</ContextMenuLabel>
            <ContextMenuItem>Mark as read</ContextMenuItem>
            <ContextMenuItem>Copy channel link</ContextMenuItem>
            <ContextMenuSeparator />
            <ContextMenuItem danger>Delete channel</ContextMenuItem>
          </ContextMenuContent>
        </ContextMenu>
      </Section>

      <Section title="Popover">
        <Popover>
          <PopoverTrigger asChild>
            <Button variant="secondary">View profile</Button>
          </PopoverTrigger>
          <PopoverContent>
            <div className="flex items-center gap-3">
              <Avatar name="Ada Lovelace" presence="online" />
              <div>
                <p className="text-sm font-semibold text-fg-default">Ada Lovelace</p>
                <p className="text-xs text-fg-muted">@ada</p>
              </div>
            </div>
          </PopoverContent>
        </Popover>
      </Section>

      <Section title="Tabs">
        <Tabs defaultValue="online">
          <TabsList>
            <TabsTrigger value="online">Online</TabsTrigger>
            <TabsTrigger value="all">All</TabsTrigger>
            <TabsTrigger value="pending">Pending</TabsTrigger>
          </TabsList>
          <TabsContent value="online">
            <p className="text-sm text-fg-muted">2 friends online.</p>
          </TabsContent>
          <TabsContent value="all">
            <p className="text-sm text-fg-muted">5 friends total.</p>
          </TabsContent>
          <TabsContent value="pending">
            <p className="text-sm text-fg-muted">No pending requests.</p>
          </TabsContent>
        </Tabs>
      </Section>

      <Section title="ScrollArea">
        <ScrollArea className="h-40 rounded-md border border-border-default">
          <div className="flex flex-col gap-2 p-3">
            {Array.from({ length: 30 }, (_, index) => (
              <p key={index} className="text-sm text-fg-default">
                Scrollable row {index + 1}
              </p>
            ))}
          </div>
        </ScrollArea>
      </Section>

      <Section title="Toast" description="Imperative toast() + ToastProvider mounted at the app root.">
        <div className="flex flex-wrap gap-2">
          <Button variant="secondary" onClick={() => toast({ title: 'Info', description: 'Heads up, something happened.', variant: 'info' })}>
            Trigger info
          </Button>
          <Button variant="secondary" onClick={() => toast({ title: 'Success', description: 'Friend request sent.', variant: 'success' })}>
            Trigger success
          </Button>
          <Button variant="secondary" onClick={() => toast({ title: 'Warning', description: 'Message is close to the length limit.', variant: 'warning' })}>
            Trigger warning
          </Button>
          <Button variant="secondary" onClick={() => toast({ title: 'Error', description: 'Failed to send message.', variant: 'danger' })}>
            Trigger error
          </Button>
        </div>
      </Section>

      <Section title="Spinner & Skeleton">
        <div className="flex items-center gap-6">
          <Spinner size="sm" />
          <Spinner size="md" />
          <Spinner size="lg" />
        </div>
        <div className="flex flex-col gap-3">
          <div className="flex items-center gap-3">
            <Skeleton className="size-10 rounded-full" />
            <div className="flex flex-1 flex-col gap-2">
              <Skeleton className="h-3 w-1/3" />
              <Skeleton className="h-3 w-2/3" />
            </div>
          </div>
        </div>
      </Section>

      <Section title="EmptyState">
        <EmptyState
          icon={Inbox}
          title="No messages yet"
          description="Send the first message to get the conversation started."
          action={<Button variant="primary">Compose message</Button>}
        />
      </Section>
    </div>
  )
}
