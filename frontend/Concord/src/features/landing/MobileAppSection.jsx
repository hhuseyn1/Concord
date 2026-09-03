import { Bell, MessageCircle, Smartphone, Users } from 'lucide-react'
import { Reveal } from './Reveal'

export function MobileAppSection() {
  return (
    <section className="bg-surface-sidebar py-24">
      <div className="mx-auto grid max-w-6xl items-center gap-12 px-4 sm:px-6 lg:grid-cols-2 lg:px-8">
        <Reveal className="order-2 lg:order-1">
          <h2 className="text-3xl font-bold text-fg-heading sm:text-4xl">Stay connected wherever you go.</h2>
          <p className="mt-4 max-w-md text-lg text-fg-muted">
            The Concord mobile app brings your servers, DMs, and calls to Android — so you're never far from your
            community.
          </p>

          <div className="mt-8">
            <button
              type="button"
              disabled
              aria-disabled="true"
              title="The Android app isn't published yet — check back soon."
              className="inline-flex cursor-not-allowed items-center gap-3 rounded-md border border-border-default bg-surface-base px-5 py-3 text-left opacity-70"
            >
              <Smartphone className="size-6 shrink-0 text-fg-muted" aria-hidden="true" />
              <span>
                <span className="block text-sm font-semibold text-fg-default">Download Android App</span>
                <span className="block text-xs text-fg-muted">Coming soon</span>
              </span>
            </button>
          </div>
        </Reveal>

        <Reveal delay={150} className="order-1 flex justify-center lg:order-2">
          <div className="relative flex h-96 w-52 flex-col overflow-hidden rounded-[2rem] border-4 border-surface-base bg-surface-base shadow-lg ring-1 ring-border-default">
            <div className="mx-auto mt-2 h-4 w-20 shrink-0 rounded-full bg-surface-rail" aria-hidden="true" />

            <div className="flex h-10 shrink-0 items-center gap-2 border-b border-border-subtle px-3">
              <span className="flex size-6 items-center justify-center rounded-full bg-brand text-[10px] font-semibold text-fg-on-brand">
                C
              </span>
              <span className="text-xs font-semibold text-fg-heading">Concord</span>
              <Bell className="ml-auto size-3.5 text-fg-muted" aria-hidden="true" />
            </div>

            <div className="flex flex-1 flex-col gap-2 p-3">
              {[Users, MessageCircle, MessageCircle].map((Icon, index) => (
                <div key={index} className="flex items-center gap-2 rounded-lg bg-fg-default/5 px-2 py-2">
                  <span className="flex size-7 shrink-0 items-center justify-center rounded-full bg-brand/20 text-brand">
                    <Icon className="size-3.5" aria-hidden="true" />
                  </span>
                  <div className="min-w-0 flex-1">
                    <div className="h-2 w-3/4 rounded-full bg-fg-default/15" />
                    <div className="mt-1.5 h-1.5 w-1/2 rounded-full bg-fg-default/10" />
                  </div>
                </div>
              ))}
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  )
}
