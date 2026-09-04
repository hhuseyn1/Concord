import {
  AtSign,
  Compass,
  MessageCircle,
  Radio,
  Search,
  ShieldCheck,
  Smile,
  Video,
} from 'lucide-react'
import { Reveal } from './Reveal'

const FEATURES = [
  {
    icon: MessageCircle,
    title: 'Real-time messaging',
    description: 'Instant text chat in every channel and DM, powered by live SignalR connections - no refreshing, ever.',
  },
  {
    icon: Compass,
    title: 'Servers & channels',
    description: 'Create a server for your community, organize it into text and voice channels, and invite people in.',
  },
  {
    icon: Video,
    title: 'Voice & video calls',
    description: 'Jump into a voice channel or start a video call with a friend - talk face to face, no extra app needed.',
  },
  {
    icon: Radio,
    title: 'Live presence',
    description: 'See who\'s online, idle, or busy at a glance, so you always know who\'s around to talk.',
  },
  {
    icon: AtSign,
    title: 'Mentions & notifications',
    description: 'Ping someone with @mentions and get notified the moment something needs your attention.',
  },
  {
    icon: Search,
    title: 'Global search',
    description: 'Find any message across your servers and conversations in seconds.',
  },
  {
    icon: ShieldCheck,
    title: 'Roles & moderation',
    description: 'Fine-grained per-server roles and permissions, plus kick, ban, timeout, and mute tools for your mods.',
  },
  {
    icon: Smile,
    title: 'Profiles you control',
    description: 'A custom avatar, username, and status that travel with you across every server.',
  },
]

export function FeaturesSection() {
  return (
    <section id="features" className="bg-surface-sidebar py-24">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <Reveal className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-bold text-fg-heading sm:text-4xl">Everything your community needs</h2>
          <p className="mt-4 text-lg text-fg-muted">
            Concord bundles the essentials - chat, voice, video, and moderation - into one focused app.
          </p>
        </Reveal>

        <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {FEATURES.map((feature, index) => (
            <Reveal key={feature.title} delay={(index % 4) * 75}>
              <div className="group h-full rounded-lg border border-border-default bg-surface-base p-6 shadow-sm transition-all duration-200 hover:-translate-y-1 hover:border-brand/40 hover:shadow-lg">
                <span className="inline-flex size-11 items-center justify-center rounded-xl bg-brand-bg text-brand transition-colors group-hover:bg-brand group-hover:text-fg-on-brand">
                  <feature.icon className="size-5" aria-hidden="true" />
                </span>
                <h3 className="mt-4 text-base font-semibold text-fg-heading">{feature.title}</h3>
                <p className="mt-2 text-sm text-fg-muted">{feature.description}</p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}
