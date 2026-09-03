import { Component } from 'react'
import { AlertTriangle } from 'lucide-react'
import { Button } from '../components/ui/Button'
import { EmptyState } from '../components/ui/EmptyState'

export class ErrorBoundary extends Component {
  state = { hasError: false }

  static getDerivedStateFromError() {
    return { hasError: true }
  }

  componentDidCatch(error, errorInfo) {
    console.error('Unhandled error caught by ErrorBoundary:', error, errorInfo)
  }

  handleReload = () => {
    window.location.reload()
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="flex h-dvh w-full items-center justify-center bg-surface-base p-6 text-fg-default">
          <EmptyState
            icon={AlertTriangle}
            title="Something went wrong"
            description="Concord hit an unexpected error. Reloading the page usually fixes it."
            action={
              <Button variant="secondary" onClick={this.handleReload}>
                Reload Concord
              </Button>
            }
            className="max-w-sm border-none"
          />
        </div>
      )
    }

    return this.props.children
  }
}
