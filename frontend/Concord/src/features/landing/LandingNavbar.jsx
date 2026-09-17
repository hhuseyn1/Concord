import { Menu, X } from 'lucide-react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'
import { ThemeToggle } from '../../components/ui/ThemeToggle'
import { LandingLanguageSwitcher } from './LandingLanguageSwitcher'
import { linkButtonClasses } from './linkButtonClasses'

export function LandingNavbar() {
  const { t } = useTranslation()
  const [mobileOpen, setMobileOpen] = useState(false)

  const NAV_LINKS = [
    { href: '#features', label: t('landing.nav.features') },
    { href: '#how-it-works', label: t('landing.nav.howItWorks') },
    { href: '#faq', label: t('landing.nav.faq') },
    { href: '#contact', label: t('landing.nav.contact') },
  ]

  return (
    <header className="sticky top-0 z-30 border-b border-border-subtle bg-surface-base/80 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4 sm:px-6 lg:px-8">
        <a href="#top" className="flex shrink-0 items-center gap-2">
          <img src="/logo-icon.png" alt="" className="size-8" aria-hidden="true" />
          <span className="text-lg font-semibold text-fg-heading">Concord</span>
        </a>

        {/* Tighter gaps at `md` (where the logo, four links, language, theme toggle and both
          * auth buttons are all on one row) so the bar still fits at the largest text size;
          * the roomier spacing comes back from `lg` up. */}
        <nav aria-label="Primary" className="hidden items-center gap-5 md:flex lg:gap-8">
          {NAV_LINKS.map((link) => (
            <a
              key={link.href}
              href={link.href}
              className="text-sm font-medium text-fg-muted transition-colors hover:text-fg-default"
            >
              {link.label}
            </a>
          ))}
        </nav>

        <div className="hidden items-center gap-2 md:flex">
          <LandingLanguageSwitcher />
          <ThemeToggle />
          <div className="ml-1 flex items-center gap-3">
            <Link to="/login" className={linkButtonClasses('ghost', 'md')}>
              {t('landing.nav.logIn')}
            </Link>
            <Link to="/register" className={linkButtonClasses('primary', 'md')}>
              {t('landing.nav.register')}
            </Link>
          </div>
        </div>

        {/* On mobile the two appearance controls stay outside the collapsible
          * menu - they're one-tap preferences, not navigation. */}
        <div className="flex items-center gap-1 md:hidden">
          <LandingLanguageSwitcher />
          <ThemeToggle />
          <button
            type="button"
            aria-label={mobileOpen ? t('landing.nav.closeMenu') : t('landing.nav.openMenu')}
            aria-expanded={mobileOpen}
            aria-controls="landing-mobile-nav"
            onClick={() => setMobileOpen((open) => !open)}
            className="flex size-10 items-center justify-center rounded-md text-fg-default hover:bg-fg-default/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand"
          >
            {mobileOpen ? <X className="size-5" aria-hidden="true" /> : <Menu className="size-5" aria-hidden="true" />}
          </button>
        </div>
      </div>

      {mobileOpen && (
        <nav
          id="landing-mobile-nav"
          aria-label="Primary"
          className="flex flex-col gap-1 border-t border-border-subtle bg-surface-base px-4 py-3 md:hidden"
        >
          {NAV_LINKS.map((link) => (
            <a
              key={link.href}
              href={link.href}
              onClick={() => setMobileOpen(false)}
              className="rounded-md px-2 py-2 text-sm font-medium text-fg-muted hover:bg-fg-default/10 hover:text-fg-default"
            >
              {link.label}
            </a>
          ))}
          <div className="mt-2 flex gap-2 border-t border-border-subtle pt-3">
            <Link to="/login" className={linkButtonClasses('secondary', 'md', 'flex-1')}>
              {t('landing.nav.logIn')}
            </Link>
            <Link to="/register" className={linkButtonClasses('primary', 'md', 'flex-1')}>
              {t('landing.nav.register')}
            </Link>
          </div>
        </nav>
      )}
    </header>
  )
}
