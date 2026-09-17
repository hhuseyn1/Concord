import { ArrowRight } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'
import { AppPreviewMock } from './AppPreviewMock'
import { linkButtonClasses } from './linkButtonClasses'
import { Reveal } from './Reveal'

export function HeroSection() {
  const { t } = useTranslation()

  return (
    <section id="top" className="relative overflow-hidden">
      <div
        aria-hidden="true"
        className="landing-orb pointer-events-none absolute -top-24 -left-24 size-96 rounded-full bg-brand/25 blur-3xl"
      />
      <div
        aria-hidden="true"
        className="landing-orb-slow pointer-events-none absolute top-32 -right-24 size-96 rounded-full bg-accent/20 blur-3xl"
      />

      <div className="relative mx-auto grid max-w-6xl gap-12 px-4 py-20 sm:px-6 sm:py-28 lg:grid-cols-2 lg:items-center lg:px-8 lg:py-32">
        <Reveal>
          <p className="mb-4 inline-flex items-center rounded-full border border-border-default bg-surface-sidebar px-3 py-1 text-xs font-medium text-fg-muted">
            {t('landing.hero.eyebrow')}
          </p>
          <h1 className="text-4xl font-bold text-balance text-fg-heading sm:text-5xl lg:text-6xl">
            {t('landing.hero.titleLine1')}
            <span className="bg-linear-to-r from-brand to-accent bg-clip-text text-transparent"> {t('landing.hero.titleHighlight')}</span>
          </h1>
          <p className="mt-6 max-w-lg text-lg text-fg-muted">{t('landing.hero.description')}</p>

          <div className="mt-8 flex flex-wrap items-center gap-4">
            <Link to="/register" className={linkButtonClasses('primary', 'xl', 'group')}>
              {t('landing.hero.getStarted')}
              <ArrowRight className="size-4 transition-transform group-hover:translate-x-0.5" aria-hidden="true" />
            </Link>
            <Link to="/login" className={linkButtonClasses('secondary', 'xl')}>
              {t('landing.hero.logIn')}
            </Link>
          </div>
        </Reveal>

        <Reveal delay={150} className="relative aspect-[16/11] w-full">
          <AppPreviewMock className="h-full" />
        </Reveal>
      </div>
    </section>
  )
}
