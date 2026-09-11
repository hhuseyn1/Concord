import { ChevronDown } from 'lucide-react'
import { useState } from 'react'
import { cn } from '../../lib/cn'
import { Reveal } from './Reveal'

const FAQS = [
  {
    question: 'What is Concord?',
    answer:
      'Concord is a real-time chat platform for communities. Create or join a server, organize it into text and voice channels, and talk with your people through messages, voice, and video.',
  },
  {
    question: 'How do I get started?',
    answer:
      'Register for a free account, then either join a server through an invite link or create your own. You can start chatting right away.',
  },
  {
    question: 'Can I talk with voice and video, not just text?',
    answer:
      'Yes. Join any voice channel in a server for live audio, or start a video call directly with a friend from a direct message.',
  },
  {
    question: 'How is my account kept secure?',
    answer:
      'You can enable two-factor authentication for an extra layer of protection, and sign in on a new device by scanning a QR code from an already-logged-in session.',
  },
  {
    question: 'Can I moderate my own community?',
    answer:
      'Yes. Server owners can create custom roles with fine-grained permissions, and moderators can kick, ban, time out, or mute members as needed.',
  },
  {
    question: 'Is there a mobile app?',
    answer:
      "A dedicated Android app is on the way. It's in its final stages, and we'll add the download link here as soon as it's ready.",
  },
]

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
  const [openIndex, setOpenIndex] = useState(0)

  return (
    <section id="faq" className="py-24">
      <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
        <Reveal className="text-center">
          <h2 className="text-3xl font-bold text-fg-heading sm:text-4xl">Frequently asked questions</h2>
          <p className="mt-4 text-lg text-fg-muted">Everything you need to know before you jump in.</p>
        </Reveal>

        <Reveal delay={100} className="mt-10 border-t border-border-default">
          {FAQS.map((faq, index) => (
            <FaqItem
              key={faq.question}
              id={`faq-item-${index}`}
              question={faq.question}
              answer={faq.answer}
              isOpen={openIndex === index}
              onToggle={() => setOpenIndex((current) => (current === index ? -1 : index))}
            />
          ))}
        </Reveal>
      </div>
    </section>
  )
}
