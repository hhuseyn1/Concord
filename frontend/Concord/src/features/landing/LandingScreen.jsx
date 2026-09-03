import { useEffect } from 'react'
import './landing.css'
import { FaqSection } from './FaqSection'
import { FeaturesSection } from './FeaturesSection'
import { FinalCtaSection } from './FinalCtaSection'
import { HeroSection } from './HeroSection'
import { HowItWorksSection } from './HowItWorksSection'
import { LandingFooter } from './LandingFooter'
import { LandingNavbar } from './LandingNavbar'
import { MobileAppSection } from './MobileAppSection'

export function LandingScreen() {
  // Smooth-scrolls the in-page nav/footer anchors (#features, #faq, ...) without opting the whole
  // app into smooth scrolling - reset on unmount so it doesn't leak into other routes.
  useEffect(() => {
    const root = document.documentElement
    const previous = root.style.scrollBehavior
    root.style.scrollBehavior = 'smooth'
    return () => {
      root.style.scrollBehavior = previous
    }
  }, [])

  return (
    <div className="min-h-dvh bg-surface-base text-fg-default">
      <LandingNavbar />
      <main>
        <HeroSection />
        <FeaturesSection />
        <HowItWorksSection />
        <MobileAppSection />
        <FaqSection />
        <FinalCtaSection />
      </main>
      <LandingFooter />
    </div>
  )
}
