import { Gift, Hash, Mic, Plus, Search, Send, Smile, Volume2 } from 'lucide-react'

const SERVERS = [
  { label: 'C', active: true },
  { label: 'DS', color: 'bg-accent/20 text-accent' },
  { label: 'GD', color: 'bg-success-bg text-success' },
  { label: 'FR', color: 'bg-warning-bg text-warning' },
]

const CHANNELS = [
  { name: 'welcome', icon: Hash },
  { name: 'general', icon: Hash, active: true },
  { name: 'screenshots', icon: Hash },
  { name: 'General Voice', icon: Volume2, voice: true },
]

const MESSAGES = [
  {
    name: 'Aria',
    color: 'bg-brand/25 text-brand',
    time: '10:41 AM',
    text: 'Pushed the new build - voice quality should feel a lot snappier now.',
  },
  {
    name: 'Rowan',
    color: 'bg-accent/25 text-accent',
    time: '10:42 AM',
    text: 'Nice! Jumping into General Voice to test it out.',
  },
  {
    name: 'Nova',
    color: 'bg-success-bg text-success',
    time: '10:44 AM',
    mention: true,
    text: '@Aria sounds great on my end 🎧',
  },
]

export function AppPreviewMock({ className }) {
  return (
    <div
      className={`flex h-full w-full overflow-hidden rounded-xl border border-border-default bg-surface-base shadow-lg ${className ?? ''}`}
      aria-hidden="true"
    >
      <div className="flex w-14 shrink-0 flex-col items-center gap-2 bg-surface-rail py-3">
        <span className="flex size-9 items-center justify-center rounded-xl bg-brand text-xs font-semibold text-fg-on-brand">
          C
        </span>
        <div className="h-px w-6 rounded-full bg-border-default" />
        {SERVERS.slice(1).map((server) => (
          <span
            key={server.label}
            className={`flex size-9 items-center justify-center rounded-2xl text-[10px] font-semibold ${server.color}`}
          >
            {server.label}
          </span>
        ))}
        <span className="flex size-9 items-center justify-center rounded-2xl bg-fg-default/10 text-fg-muted">
          <Plus className="size-4" />
        </span>
      </div>

      <div className="hidden w-40 shrink-0 flex-col border-r border-border-default bg-surface-sidebar sm:flex">
        <div className="flex h-10 shrink-0 items-center border-b border-border-subtle px-3">
          <p className="truncate text-xs font-semibold text-fg-heading">Concord Devs</p>
        </div>
        <div className="flex flex-1 flex-col gap-0.5 p-2 pt-3">
          {CHANNELS.map((channel) => (
            <div
              key={channel.name}
              className={`flex items-center gap-1.5 rounded-md px-2 py-1 text-[11px] font-medium ${
                channel.active ? 'bg-fg-default/10 text-fg-default' : 'text-fg-muted'
              }`}
            >
              <channel.icon className="size-3.5 shrink-0" />
              <span className="truncate">{channel.name}</span>
            </div>
          ))}
        </div>
        <div className="flex items-center gap-2 border-t border-border-subtle p-2">
          <span className="relative flex size-6 shrink-0 items-center justify-center rounded-full bg-brand/30 text-[9px] font-semibold text-brand">
            YOU
            <span className="absolute -right-0.5 -bottom-0.5 size-2 rounded-full bg-presence-online ring-2 ring-surface-sidebar" />
          </span>
          <span className="truncate text-[11px] font-medium text-fg-default">you</span>
        </div>
      </div>

      <div className="flex min-w-0 flex-1 flex-col">
        <div className="flex h-10 shrink-0 items-center gap-2 border-b border-border-subtle px-3 shadow-sm">
          <Hash className="size-4 shrink-0 text-fg-muted" />
          <p className="truncate text-xs font-semibold text-fg-heading">general</p>
          <Search className="ml-auto size-3.5 shrink-0 text-fg-muted" />
        </div>

        <div className="flex flex-1 flex-col justify-end gap-3 overflow-hidden px-3 py-3">
          {MESSAGES.map((message) => (
            <div key={message.name + message.time} className="flex items-start gap-2">
              <span
                className={`flex size-7 shrink-0 items-center justify-center rounded-full text-[10px] font-semibold ${message.color}`}
              >
                {message.name.slice(0, 2).toUpperCase()}
              </span>
              <div className="min-w-0">
                <div className="flex items-baseline gap-1.5">
                  <span className="truncate text-[11px] font-semibold text-fg-heading">{message.name}</span>
                  <span className="shrink-0 text-[9px] text-fg-muted">{message.time}</span>
                </div>
                <p className="text-[11px] leading-snug break-words text-fg-default">
                  {message.mention ? (
                    <>
                      <span className="rounded bg-brand-bg px-1 text-brand">@Aria</span>
                      {message.text.replace('@Aria', '')}
                    </>
                  ) : (
                    message.text
                  )}
                </p>
              </div>
            </div>
          ))}
        </div>

        <div className="flex items-center gap-2 px-3 pb-3">
          <div className="flex h-8 flex-1 items-center gap-2 rounded-md bg-fg-default/10 px-2.5 text-fg-muted">
            <Plus className="size-3.5 shrink-0" />
            <span className="flex-1 text-[11px]">Message #general</span>
            <Gift className="size-3.5 shrink-0" />
            <Smile className="size-3.5 shrink-0" />
            <Send className="size-3.5 shrink-0" />
          </div>
        </div>
      </div>

      <div className="hidden w-32 shrink-0 flex-col border-l border-border-default bg-surface-sidebar p-2 md:flex">
        <p className="px-1 pb-2 text-[10px] font-semibold tracking-wide text-fg-muted uppercase">In voice</p>
        <div className="flex items-center gap-1.5 rounded-md bg-fg-default/5 px-1.5 py-1.5">
          <span className="flex size-6 items-center justify-center rounded-full bg-accent/25 text-[9px] font-semibold text-accent">
            RO
          </span>
          <span className="truncate text-[10px] font-medium text-fg-default">Rowan</span>
          <Mic className="ml-auto size-3 shrink-0 text-success" />
        </div>
      </div>
    </div>
  )
}
