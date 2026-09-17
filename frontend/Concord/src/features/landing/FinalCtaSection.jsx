import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'
import { linkButtonClasses } from './linkButtonClasses'
import { Reveal } from './Reveal'

export function FinalCtaSection() {
  const { t } = useTranslation()

  return (
    <section id="contact" className="py-24">
      <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        <Reveal className="relative overflow-hidden rounded-3xl border border-border-default bg-linear-to-br from-brand/15 via-surface-sidebar to-accent/10 px-6 py-16 text-center sm:px-16">
          <h2 className="text-3xl font-bold text-fg-heading sm:text-4xl">{t('landing.finalCta.title')}</h2>
          <p className="mx-auto mt-4 max-w-md text-lg text-fg-muted">{t('landing.finalCta.description')}</p>
          <div className="mt-8 flex flex-wrap items-center justify-center gap-4">
            <Link to="/register" className={linkButtonClasses('primary', 'xl')}>
              {t('landing.finalCta.register')}
            </Link>
            <Link to="/login" className={linkButtonClasses('secondary', 'xl')}>
              {t('landing.finalCta.logIn')}
            </Link>
          </div>
        </Reveal>
      </div>
    </section>
  )
}
