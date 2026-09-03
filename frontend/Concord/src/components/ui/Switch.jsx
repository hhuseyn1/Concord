import * as RadixSwitch from '@radix-ui/react-switch'
import { cn } from '../../lib/cn'

export function Switch({ checked, onCheckedChange, disabled, className, ...props }) {
  return (
    <RadixSwitch.Root
      checked={checked}
      onCheckedChange={onCheckedChange}
      disabled={disabled}
      className={cn(
        'relative h-5 w-9 shrink-0 rounded-full bg-fg-default/20 outline-none transition-colors duration-150',
        'data-[state=checked]:bg-brand',
        'focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 focus-visible:ring-offset-surface-base',
        'disabled:opacity-50 disabled:pointer-events-none',
        className,
      )}
      {...props}
    >
      <RadixSwitch.Thumb className="block size-4 translate-x-0.5 rounded-full bg-white shadow transition-transform duration-150 data-[state=checked]:translate-x-[1.125rem]" />
    </RadixSwitch.Root>
  )
}
