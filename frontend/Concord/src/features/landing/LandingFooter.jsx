import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'

export function LandingFooter() {
  const { t } = useTranslation()

  const PRODUCT_LINKS = [
    { href: '#features', label: t('landing.nav.features') },
    { href: '#how-it-works', label: t('landing.nav.howItWorks') },
    { href: '#faq', label: t('landing.nav.faq') },
    { href: '#contact', label: t('landing.nav.contact') },
  ]

  return (
    <footer className="border-t border-border-subtle bg-surface-sidebar">
      <div className="mx-auto max-w-6xl px-4 py-12 sm:px-6 lg:px-8">
        <div className="grid gap-10 sm:grid-cols-2 lg:grid-cols-4">
          <div>
            <a href="#top" className="flex items-center gap-2">
              <img src="/logo-icon.png" alt="" className="size-7" aria-hidden="true" />
              <span className="text-base font-semibold text-fg-heading">Concord</span>
            </a>
            <p className="mt-3 text-sm text-fg-muted">{t('landing.footer.tagline')}</p>
          </div>

          <div>
            <p className="text-xs font-semibold tracking-wide text-fg-muted uppercase">{t('landing.footer.product')}</p>
            <ul className="mt-3 flex flex-col gap-2">
              {PRODUCT_LINKS.map((link) => (
                <li key={link.href}>
                  <a href={link.href} className="text-sm text-fg-muted hover:text-fg-default">
                    {link.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <p className="text-xs font-semibold tracking-wide text-fg-muted uppercase">{t('landing.footer.account')}</p>
            <ul className="mt-3 flex flex-col gap-2">
              <li>
                <Link to="/login" className="text-sm text-fg-muted hover:text-fg-default">
                  {t('landing.footer.logIn')}
                </Link>
              </li>
              <li>
                <Link to="/register" className="text-sm text-fg-muted hover:text-fg-default">
                  {t('landing.footer.register')}
                </Link>
              </li>
            </ul>
          </div>

          <div>
            <p className="text-xs font-semibold tracking-wide text-fg-muted uppercase">{t('landing.footer.mobile')}</p>
            <ul className="mt-3 flex flex-col gap-2">
              <li>
                <span className="text-sm text-fg-muted" title={t('landing.mobileApp.comingSoonTitle')}>
                  {t('landing.footer.androidComingSoon')}
                </span>
              </li>
            </ul>
          </div>
        </div>

        <div className="mt-10 border-t border-border-subtle pt-6 text-sm text-fg-muted">
          {t('landing.footer.copyright', { year: new Date().getFullYear() })}
        </div>
      </div>
    </footer>
  )
}
