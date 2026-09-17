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
import { useTranslation } from 'react-i18next'
import { Reveal } from './Reveal'

const FEATURES = [
  { key: 'messaging', icon: MessageCircle },
  { key: 'servers', icon: Compass },
  { key: 'calls', icon: Video },
  { key: 'presence', icon: Radio },
  { key: 'mentions', icon: AtSign },
  { key: 'search', icon: Search },
  { key: 'moderation', icon: ShieldCheck },
  { key: 'profiles', icon: Smile },
]

export function FeaturesSection() {
  const { t } = useTranslation()

  return (
    <section id="features" className="bg-surface-sidebar py-24">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <Reveal className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-bold text-fg-heading sm:text-4xl">{t('landing.features.title')}</h2>
          <p className="mt-4 text-lg text-fg-muted">{t('landing.features.description')}</p>
        </Reveal>

        <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {FEATURES.map((feature, index) => (
            <Reveal key={feature.key} delay={(index % 4) * 75}>
              <div className="group h-full rounded-lg border border-border-default bg-surface-base p-6 shadow-sm transition-all duration-200 hover:-translate-y-1 hover:border-brand/40 hover:shadow-lg">
                <span className="inline-flex size-11 items-center justify-center rounded-xl bg-brand-bg text-brand transition-colors group-hover:bg-brand group-hover:text-fg-on-brand">
                  <feature.icon className="size-5" aria-hidden="true" />
                </span>
                <h3 className="mt-4 text-base font-semibold text-fg-heading">
                  {t(`landing.features.items.${feature.key}.title`)}
                </h3>
                <p className="mt-2 text-sm text-fg-muted">
                  {t(`landing.features.items.${feature.key}.description`)}
                </p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}
