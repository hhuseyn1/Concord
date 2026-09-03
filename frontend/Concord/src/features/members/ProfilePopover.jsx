import { useState } from 'react'
import { Popover, PopoverContent, PopoverTrigger } from '../../components/ui/Popover'
import { ProfileCard } from './ProfileCard'

export function ProfilePopover({ userId, children, side = 'right', align = 'start' }) {
  const [open, setOpen] = useState(false)

  if (!userId) return children

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>{children}</PopoverTrigger>
      <PopoverContent side={side} align={align} className="w-80 p-0">
        <ProfileCard userId={userId} />
      </PopoverContent>
    </Popover>
  )
}
