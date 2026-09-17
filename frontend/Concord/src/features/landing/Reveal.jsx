import { cn } from '../../lib/cn'
import { useRevealOnScroll } from './useRevealOnScroll'

export function Reveal({ as: Tag = 'div', delay = 0, className, children }) {
  const [ref, isVisible] = useRevealOnScroll()

  return (
    <Tag
      ref={ref}
      style={{ transitionDelay: isVisible ? `${delay}ms` : '0ms' }}
      className={cn(
        'transition-all duration-700 [transition-timing-function:var(--ease-emphasized)] motion-reduce:transition-none',
        isVisible ? 'translate-y-0 opacity-100' : 'translate-y-6 opacity-0',
        className,
      )}
    >
      {children}
    </Tag>
  )
}
