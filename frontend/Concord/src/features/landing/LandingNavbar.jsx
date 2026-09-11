import { Menu, X } from 'lucide-react'
import { useState } from 'react'
import { Link } from 'react-router-dom'
import { linkButtonClasses } from './linkButtonClasses'

const NAV_LINKS = [
  { href: '#features', label: 'Features' },
  { href: '#how-it-works', label: 'How it works' },
  { href: '#faq', label: 'FAQ' },
  { href: '#contact', label: 'Contact' },
]

export function LandingNavbar() {
  const [mobileOpen, setMobileOpen] = useState(false)

  return (
    <header className="sticky top-0 z-30 border-b border-border-subtle bg-surface-base/80 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4 sm:px-6 lg:px-8">
        <a href="#top" className="flex shrink-0 items-center gap-2">
          <img src="/favicon.svg" alt="" className="size-8" aria-hidden="true" />
          <span className="text-lg font-semibold text-fg-heading">Concord</span>
        </a>

        <nav aria-label="Primary" className="hidden items-center gap-8 md:flex">
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

        <div className="hidden items-center gap-3 md:flex">
          <Link to="/login" className={linkButtonClasses('ghost', 'md')}>
            Log In
          </Link>
          <Link to="/register" className={linkButtonClasses('primary', 'md')}>
            Register
          </Link>
        </div>

        <button
          type="button"
          aria-label={mobileOpen ? 'Close menu' : 'Open menu'}
          aria-expanded={mobileOpen}
          aria-controls="landing-mobile-nav"
          onClick={() => setMobileOpen((open) => !open)}
          className="flex size-9 items-center justify-center rounded-md text-fg-default hover:bg-fg-default/10 md:hidden"
        >
          {mobileOpen ? <X className="size-5" aria-hidden="true" /> : <Menu className="size-5" aria-hidden="true" />}
        </button>
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
              Log In
            </Link>
            <Link to="/register" className={linkButtonClasses('primary', 'md', 'flex-1')}>
              Register
            </Link>
          </div>
        </nav>
      )}
    </header>
  )
}
