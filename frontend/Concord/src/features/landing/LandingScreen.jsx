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
