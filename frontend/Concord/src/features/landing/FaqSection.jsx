import { ChevronDown } from 'lucide-react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { cn } from '../../lib/cn'
import { Reveal } from './Reveal'

const FAQ_KEYS = ['whatIsConcord', 'gettingStarted', 'voiceVideo', 'security', 'moderation', 'mobileApp']

function FaqItem({ id, question, answer, isOpen, onToggle }) {
  const panelId = `${id}-panel`
  return (
    <div className="border-b border-border-default">
      <button
        type="button"
        id={id}
        onClick={onToggle}
        aria-expanded={isOpen}
        aria-controls={panelId}
        className="flex w-full items-center justify-between gap-4 py-5 text-left"
      >
        <span className="text-base font-medium text-fg-heading">{question}</span>
        <ChevronDown
          className={cn('size-5 shrink-0 text-fg-muted transition-transform duration-200', isOpen && 'rotate-180')}
          aria-hidden="true"
        />
      </button>
      <div
        id={panelId}
        role="region"
        aria-labelledby={id}
        className={cn(
          'grid transition-all duration-200 [transition-timing-function:var(--ease-standard)]',
          isOpen ? 'grid-rows-[1fr] opacity-100' : 'grid-rows-[0fr] opacity-0',
        )}
      >
        <p className="overflow-hidden pb-5 text-sm text-fg-muted">{answer}</p>
      </div>
    </div>
  )
}

export function FaqSection() {
  const { t } = useTranslation()
  const [openIndex, setOpenIndex] = useState(0)

  return (
    <section id="faq" className="py-24">
      <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
        <Reveal className="text-center">
          <h2 className="text-3xl font-bold text-fg-heading sm:text-4xl">{t('landing.faq.title')}</h2>
          <p className="mt-4 text-lg text-fg-muted">{t('landing.faq.description')}</p>
        </Reveal>

        <Reveal delay={100} className="mt-10 border-t border-border-default">
          {FAQ_KEYS.map((key, index) => (
            <FaqItem
              key={key}
              id={`faq-item-${index}`}
              question={t(`landing.faq.items.${key}.question`)}
              answer={t(`landing.faq.items.${key}.answer`)}
              isOpen={openIndex === index}
              onToggle={() => setOpenIndex((current) => (current === index ? -1 : index))}
            />
          ))}
        </Reveal>
      </div>
    </section>
  )
}
