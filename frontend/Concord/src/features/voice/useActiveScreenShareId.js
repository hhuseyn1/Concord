import { RoomEvent, Track } from 'livekit-client'
import { useEffect, useState } from 'react'

export function useActiveScreenShareId(room) {
  const [sharerId, setSharerId] = useState(null)

  useEffect(() => {
    if (!room) return undefined

    const findSharer = () => {
      const all = [room.localParticipant, ...Array.from(room.remoteParticipants.values())]
      for (const participant of all) {
        const sharing = Array.from(participant.videoTrackPublications.values()).some(
          (pub) => pub.source === Track.Source.ScreenShare && pub.track,
        )
        if (sharing) return participant.identity
      }
      return null
    }

    const update = () => setSharerId(findSharer())
    update()

    const events = [
      RoomEvent.TrackPublished,
      RoomEvent.TrackUnpublished,
      RoomEvent.TrackSubscribed,
      RoomEvent.TrackUnsubscribed,
      RoomEvent.LocalTrackPublished,
      RoomEvent.LocalTrackUnpublished,
      RoomEvent.ParticipantDisconnected,
    ]
    for (const event of events) room.on(event, update)
    return () => {
      for (const event of events) room.off(event, update)
      setSharerId(null)
    }
  }, [room])

  return sharerId
}
