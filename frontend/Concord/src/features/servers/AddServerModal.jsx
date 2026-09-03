import { Modal } from '../../components/ui/Modal'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../../components/ui/Tabs'
import { CreateServerForm } from './CreateServerForm'
import { JoinServerForm } from './JoinServerForm'

export function AddServerModal({ open, onOpenChange, defaultTab = 'create' }) {
  return (
    <Modal
      open={open}
      onOpenChange={onOpenChange}
      title="Add a Server"
      description="Create a new server, or join one with an invite code."
      size="sm"
    >
      <Tabs defaultValue={defaultTab}>
        <TabsList className="w-full">
          <TabsTrigger value="create" className="flex-1">
            Create
          </TabsTrigger>
          <TabsTrigger value="join" className="flex-1">
            Join
          </TabsTrigger>
        </TabsList>
        <TabsContent value="create">
          <CreateServerForm onDone={() => onOpenChange(false)} />
        </TabsContent>
        <TabsContent value="join">
          <JoinServerForm onDone={() => onOpenChange(false)} />
        </TabsContent>
      </Tabs>
    </Modal>
  )
}
