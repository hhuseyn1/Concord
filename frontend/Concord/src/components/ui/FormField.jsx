import { cloneElement, isValidElement, useId } from 'react'
import { cn } from '../../lib/cn'

export function FormField({
  label,
  error,
  hint,
  htmlFor,
  required = false,
  children,
  className,
}) {
  const generatedId = useId()
  const fieldId = htmlFor ?? generatedId
  const errorId = error ? `${fieldId}-error` : undefined
  const hintId = hint ? `${fieldId}-hint` : undefined

  const control = isValidElement(children)
    ? cloneElement(children, {
        id: children.props.id ?? fieldId,
        invalid: children.props.invalid ?? Boolean(error),
        'aria-describedby':
          children.props['aria-describedby'] ??
          ([hintId, errorId].filter(Boolean).join(' ') || undefined),
      })
    : children

  return (
    <div className={cn('flex flex-col gap-1.5', className)}>
      {label && (
        <label htmlFor={fieldId} className="text-sm font-medium text-fg-default">
          {label}
          {required && <span className="text-danger ml-0.5">*</span>}
        </label>
      )}
      {control}
      {hint && !error && (
        <p id={hintId} className="text-xs text-fg-muted">
          {hint}
        </p>
      )}
      {error && (
        <p id={errorId} role="alert" className="text-xs text-danger">
          {error}
        </p>
      )}
    </div>
  )
}
