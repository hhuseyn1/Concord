import { useTranslation } from 'react-i18next'
import { Avatar } from '../../components/ui/Avatar'
import { cn } from '../../lib/cn'

export function MentionAutocomplete({ suggestions, activeIndex, onSelect }) {
  const { t } = useTranslation()

  if (suggestions.length === 0) return null

  return (
    <div
      role="listbox"
      aria-label={t('messages.mentionSuggestions')}
      className="absolute bottom-full left-2 z-20 mb-1 w-56 overflow-hidden rounded-md border border-border-default bg-surface-base py-1 shadow-lg"
    >
      {suggestions.map((candidate, index) => {
        const displayName =
          candidate.Username || [candidate.Name, candidate.Surname].filter(Boolean).join(' ') || t('common.unknownUser')
        return (
          <button
            key={candidate.Id}
            type="button"
            role="option"
            aria-selected={index === activeIndex}
            onMouseDown={(event) => {
              event.preventDefault()
              onSelect(candidate)
            }}
            className={cn(
              'flex w-full items-center gap-2 px-2 py-1.5 text-left',
              index === activeIndex ? 'bg-brand-bg' : 'hover:bg-fg-default/5',
            )}
          >
            <Avatar src={candidate.AvatarUrl ?? undefined} name={displayName} size="sm" />
            <span className="truncate text-sm text-fg-default">{displayName}</span>
            {candidate.Username && <span className="ml-auto shrink-0 truncate text-xs text-fg-muted">@{candidate.Username}</span>}
          </button>
        )
      })}
    </div>
  )
}
