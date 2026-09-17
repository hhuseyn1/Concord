import { Compass, MessageCircle, UserPlus, Users } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Reveal } from './Reveal'

const STEPS = [
  { key: 'createAccount', icon: UserPlus },
  { key: 'joinCommunity', icon: Compass },
  { key: 'startCommunicating', icon: MessageCircle },
  { key: 'connect', icon: Users },
]

export function HowItWorksSection() {
  const { t } = useTranslation()

  return (
    <section id="how-it-works" className="py-24">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <Reveal className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-bold text-fg-heading sm:text-4xl">{t('landing.howItWorks.title')}</h2>
          <p className="mt-4 text-lg text-fg-muted">{t('landing.howItWorks.description')}</p>
        </Reveal>

        <div className="relative mt-16 grid gap-10 sm:grid-cols-2 lg:grid-cols-4">
          <div
            aria-hidden="true"
            className="absolute top-6 right-0 left-0 hidden h-px bg-linear-to-r from-transparent via-border-default to-transparent lg:block"
          />
          {STEPS.map((step, index) => (
            <Reveal key={step.key} delay={index * 100} className="relative flex flex-col items-center text-center">
              <span className="relative z-10 flex size-12 items-center justify-center rounded-full border border-border-default bg-surface-base text-brand shadow-sm">
                <step.icon className="size-5" aria-hidden="true" />
              </span>
              <span className="mt-4 text-xs font-semibold tracking-wide text-brand uppercase">
                {t('landing.howItWorks.stepLabel', { number: index + 1 })}
              </span>
              <h3 className="mt-1 text-base font-semibold text-fg-heading">
                {t(`landing.howItWorks.steps.${step.key}.title`)}
              </h3>
              <p className="mt-2 text-sm text-fg-muted">
                {t(`landing.howItWorks.steps.${step.key}.description`)}
              </p>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}
