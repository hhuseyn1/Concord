import { useTranslation } from 'react-i18next'
import { Button } from '../../components/ui/Button'
import { FormField } from '../../components/ui/FormField'
import { Input } from '../../components/ui/Input'
import { lastMonthRange, lastNMonthsRange, thisMonthRange } from './dateRangePresets'

// Shared From/To date filter with quick-range presets, used by both the Overview charts and the
// Payments tab so "this month / last month / last 3 months" behaves identically everywhere.
export function DateRangeFilter({ fromDate, toDate, onChange, fromLabel, toLabel }) {
  const { t } = useTranslation()

  function applyPreset(rangeFn) {
    const { from, to } = rangeFn()
    onChange(from, to)
  }

  return (
    <div className="flex flex-col gap-2 sm:flex-row sm:flex-wrap sm:items-end sm:gap-3">
      <div className="grid grid-cols-2 gap-3 sm:max-w-sm">
        <FormField label={fromLabel}>
          <Input type="date" value={fromDate} max={toDate || undefined} onChange={(event) => onChange(event.target.value, toDate)} />
        </FormField>
        <FormField label={toLabel}>
          <Input type="date" value={toDate} min={fromDate || undefined} onChange={(event) => onChange(fromDate, event.target.value)} />
        </FormField>
      </div>
      <div className="flex flex-wrap gap-2">
        <Button size="sm" variant="ghost" onClick={() => applyPreset(thisMonthRange)}>
          {t('admin.dateRangeThisMonth')}
        </Button>
        <Button size="sm" variant="ghost" onClick={() => applyPreset(lastMonthRange)}>
          {t('admin.dateRangeLastMonth')}
        </Button>
        <Button size="sm" variant="ghost" onClick={() => applyPreset(() => lastNMonthsRange(3))}>
          {t('admin.dateRangeLast3Months')}
        </Button>
      </div>
    </div>
  )
}
