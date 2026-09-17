import { ChevronLeft, ChevronRight } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Button } from './Button'
import { EmptyState } from './EmptyState'
import { Skeleton } from './Skeleton'

export function DataTable({
  columns,
  rows,
  rowKey = (row) => row.Id,
  loading = false,
  error = false,
  errorTitle,
  errorDescription,
  emptyIcon,
  emptyTitle,
  emptyDescription,
  page,
  totalPages,
  totalCount,
  isFetching = false,
  onPageChange,
  skeletonRowCount = 6,
  skeletonRowClassName = 'h-12 w-full rounded-md',
}) {
  const { t } = useTranslation()

  if (loading) {
    return (
      <div className="flex flex-col gap-2">
        {Array.from({ length: skeletonRowCount }, (_, index) => (
          <Skeleton key={index} className={skeletonRowClassName} />
        ))}
      </div>
    )
  }

  if (error) {
    return <EmptyState title={errorTitle} description={errorDescription} />
  }

  if (rows.length === 0) {
    return <EmptyState icon={emptyIcon} title={emptyTitle} description={emptyDescription} />
  }

  return (
    <div className="flex flex-col gap-3">
      <div className="overflow-x-auto rounded-md border border-border-default">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-border-default bg-surface-sidebar text-xs text-fg-muted uppercase">
            <tr>
              {columns.map((column) => (
                <th key={column.key} scope="col" className="px-3 py-2 font-semibold">
                  {column.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-border-default">
            {rows.map((row) => (
              <tr key={rowKey(row)}>
                {columns.map((column) => (
                  <td key={column.key} className={column.cellClassName ?? 'px-3 py-2'}>
                    {column.render(row)}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {totalCount > 0 && onPageChange && (
        <div className="flex items-center justify-between text-sm text-fg-muted">
          <span>{t('admin.pageSummary', { page, totalPages, total: totalCount })}</span>
          <div className="flex gap-2">
            <Button
              size="sm"
              variant="secondary"
              disabled={page <= 1 || isFetching}
              onClick={() => onPageChange(Math.max(1, page - 1))}
            >
              <ChevronLeft className="size-4" aria-hidden="true" />
              {t('admin.previous')}
            </Button>
            <Button
              size="sm"
              variant="secondary"
              disabled={page >= totalPages || isFetching}
              onClick={() => onPageChange(page + 1)}
            >
              {t('admin.next')}
              <ChevronRight className="size-4" aria-hidden="true" />
            </Button>
          </div>
        </div>
      )}
    </div>
  )
}
