import { ChevronDown, ChevronUp } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Button } from '../../components/ui/Button'

export function SortControls({ fields, sortBy, sortDirection, onSort }) {
  const { t } = useTranslation()

  function handleClick(field) {
    if (sortBy !== field) {
      onSort(field, 'Asc')
    } else if (sortDirection === 'Asc') {
      onSort(field, 'Desc')
    } else {
      onSort(null, null)
    }
  }

  return (
    <div className="flex flex-wrap items-center gap-2">
      <span className="text-xs text-fg-muted">{t('admin.sortBy')}</span>
      {fields.map((field) => {
        const isActive = sortBy === field.value
        const Icon = sortDirection === 'Asc' ? ChevronUp : ChevronDown
        return (
          <Button
            key={field.value}
            size="sm"
            variant={isActive ? 'secondary' : 'ghost'}
            onClick={() => handleClick(field.value)}
            aria-label={
              isActive
                ? t(sortDirection === 'Asc' ? 'admin.sortAscending' : 'admin.sortDescending', { field: t(field.label) })
                : t('admin.sortByField', { field: t(field.label) })
            }
          >
            {t(field.label)}
            {isActive && <Icon className="size-3.5" aria-hidden="true" />}
          </Button>
        )
      })}
    </div>
  )
}
