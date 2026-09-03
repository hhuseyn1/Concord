import { Link } from 'react-router-dom'

const PRODUCT_LINKS = [
  { href: '#features', label: 'Features' },
  { href: '#how-it-works', label: 'How it works' },
  { href: '#faq', label: 'FAQ' },
  { href: '#contact', label: 'Contact' },
]

export function LandingFooter() {
  return (
    <footer className="border-t border-border-subtle bg-surface-sidebar">
      <div className="mx-auto max-w-6xl px-4 py-12 sm:px-6 lg:px-8">
        <div className="grid gap-10 sm:grid-cols-2 lg:grid-cols-4">
          <div>
            <a href="#top" className="flex items-center gap-2">
              <img src="/favicon.svg" alt="" className="size-7" aria-hidden="true" />
              <span className="text-base font-semibold text-fg-heading">Concord</span>
            </a>
            <p className="mt-3 text-sm text-fg-muted">
              Real-time messaging, voice &amp; video, and communities — all in one place.
            </p>
          </div>

          <div>
            <p className="text-xs font-semibold tracking-wide text-fg-muted uppercase">Product</p>
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
            <p className="text-xs font-semibold tracking-wide text-fg-muted uppercase">Account</p>
            <ul className="mt-3 flex flex-col gap-2">
              <li>
                <Link to="/login" className="text-sm text-fg-muted hover:text-fg-default">
                  Log In
                </Link>
              </li>
              <li>
                <Link to="/register" className="text-sm text-fg-muted hover:text-fg-default">
                  Register
                </Link>
              </li>
            </ul>
          </div>

          <div>
            <p className="text-xs font-semibold tracking-wide text-fg-muted uppercase">Mobile</p>
            <ul className="mt-3 flex flex-col gap-2">
              <li>
                <span className="text-sm text-fg-muted" title="The Android app isn't published yet.">
                  Android app — coming soon
                </span>
              </li>
            </ul>
          </div>
        </div>

        <div className="mt-10 border-t border-border-subtle pt-6 text-sm text-fg-muted">
          © {new Date().getFullYear()} Concord. All rights reserved.
        </div>
      </div>
    </footer>
  )
}
