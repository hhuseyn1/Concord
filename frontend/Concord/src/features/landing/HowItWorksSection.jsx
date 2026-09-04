import { Compass, MessageCircle, UserPlus, Users } from 'lucide-react'
import { Reveal } from './Reveal'

const STEPS = [
  {
    icon: UserPlus,
    title: 'Create an account',
    description: 'Sign up with your email in under a minute - no downloads required to get started.',
  },
  {
    icon: Compass,
    title: 'Join or create a community',
    description: 'Use an invite link to join a server, or start your own and set it up exactly how you want.',
  },
  {
    icon: MessageCircle,
    title: 'Start communicating',
    description: 'Chat in text channels, share files, and mention the people you need to reach.',
  },
  {
    icon: Users,
    title: 'Connect with others',
    description: 'Add friends, send direct messages, and hop on voice or video whenever you want to talk live.',
  },
]

export function HowItWorksSection() {
  return (
    <section id="how-it-works" className="py-24">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <Reveal className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-bold text-fg-heading sm:text-4xl">Get started in four steps</h2>
          <p className="mt-4 text-lg text-fg-muted">From sign-up to your first conversation, in minutes.</p>
        </Reveal>

        <div className="relative mt-16 grid gap-10 sm:grid-cols-2 lg:grid-cols-4">
          <div
            aria-hidden="true"
            className="absolute top-6 right-0 left-0 hidden h-px bg-linear-to-r from-transparent via-border-default to-transparent lg:block"
          />
          {STEPS.map((step, index) => (
            <Reveal key={step.title} delay={index * 100} className="relative flex flex-col items-center text-center">
              <span className="relative z-10 flex size-12 items-center justify-center rounded-full border border-border-default bg-surface-base text-brand shadow-sm">
                <step.icon className="size-5" aria-hidden="true" />
              </span>
              <span className="mt-4 text-xs font-semibold tracking-wide text-brand uppercase">Step {index + 1}</span>
              <h3 className="mt-1 text-base font-semibold text-fg-heading">{step.title}</h3>
              <p className="mt-2 text-sm text-fg-muted">{step.description}</p>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}
