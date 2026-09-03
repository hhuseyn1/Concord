import { useState } from 'react'
import { useLocation } from 'react-router-dom'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../../components/ui/Tabs'
import { AddFriendTab } from './AddFriendTab'
import { BlockedTab } from './BlockedTab'
import { FriendsTab } from './FriendsTab'
import { PendingTab } from './PendingTab'

export function FriendsScreen() {
  const location = useLocation()
  return <FriendsScreenTabs key={location.key} initialTab={location.state?.tab ?? 'friends'} />
}

function FriendsScreenTabs({ initialTab }) {
  const [tab, setTab] = useState(initialTab)

  return (
    <div className="flex flex-1 flex-col gap-4 p-6">
      <div>
        <h1 className="text-lg font-semibold text-fg-heading">Friends</h1>
        <p className="text-sm text-fg-muted">
          Manage friend requests and blocks. Message a friend directly from the Friends tab, or find
          your conversations in the sidebar.
        </p>
      </div>

      <Tabs value={tab} onValueChange={setTab}>
        <TabsList>
          <TabsTrigger value="friends">Friends</TabsTrigger>
          <TabsTrigger value="pending">Pending</TabsTrigger>
          <TabsTrigger value="blocked">Blocked</TabsTrigger>
          <TabsTrigger value="add">Add Friend</TabsTrigger>
        </TabsList>

        <TabsContent value="friends">
          <FriendsTab />
        </TabsContent>
        <TabsContent value="pending">
          <PendingTab />
        </TabsContent>
        <TabsContent value="blocked">
          <BlockedTab />
        </TabsContent>
        <TabsContent value="add">
          <AddFriendTab />
        </TabsContent>
      </Tabs>
    </div>
  )
}
