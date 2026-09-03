import { Outlet } from 'react-router-dom'

export function MessageAreaShell({ membersOpen = false, memberPanel = null }) {
  return (
    <div className="flex min-h-0 flex-1">
      <main className="flex min-w-0 flex-1 flex-col overflow-y-auto bg-surface-base">
        <Outlet />
      </main>

      {membersOpen && (
        <aside
          aria-label="Members"
          className="hidden w-60 shrink-0 border-l border-border-subtle bg-surface-sidebar md:flex md:flex-col"
        >
          {memberPanel}
        </aside>
      )}
    </div>
  )
}
