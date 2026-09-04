import { useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useChannels } from './channelsQueries'

export function useChannelNavigationShortcuts() {
  const navigate = useNavigate()
  const { serverId, channelId } = useParams()
  const { data: channels } = useChannels(serverId, { enabled: Boolean(serverId) })

  useEffect(() => {
    if (!serverId || !channels?.length) return undefined

    const orderedChannels = [
      ...channels.filter((channel) => channel.Type === 'Text'),
      ...channels.filter((channel) => channel.Type === 'Voice'),
    ]

    const handleKeyDown = (event) => {
      if (!event.altKey || (event.key !== 'ArrowUp' && event.key !== 'ArrowDown')) return

      const target = event.target
      const isEditable =
        target instanceof HTMLElement &&
        (target.tagName === 'TEXTAREA' || target.tagName === 'INPUT' || target.isContentEditable)
      if (isEditable) return

      const currentIndex = orderedChannels.findIndex((channel) => channel.Id === channelId)
      const delta = event.key === 'ArrowUp' ? -1 : 1
      const nextIndex = (currentIndex + delta + orderedChannels.length) % orderedChannels.length
      const nextChannel = orderedChannels[nextIndex]
      if (!nextChannel || nextChannel.Id === channelId) return

      event.preventDefault()
      navigate(`/cabinet/servers/${serverId}/channels/${nextChannel.Id}`)
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [serverId, channelId, channels, navigate])
}
