import { useCallback, useEffect, useRef, useState } from 'react'
import { DisconnectReason, Room, RoomEvent, Track } from 'livekit-client'
import { useQueryClient } from '@tanstack/react-query'
import i18n from '../i18n'
import { createVoiceHub } from '../api/hubs/voiceHub'
import { createDirectMessagesHub } from '../api/hubs/directMessagesHub'
import * as directCallsService from '../api/directCallsService'
import * as voiceService from '../api/voiceService'
import * as directVoiceService from '../api/directVoiceService'
import { toast } from '../components/ui/Toast'
import { mapGetVoiceTokenError, mapInvoluntaryDisconnectMessage, mapVoiceConnectError } from '../features/voice/voiceErrors'
import { mapCallActionError, mapStartCallError } from '../features/directMessages/directCallsErrors'
import { directCallsKeys } from '../features/directMessages/directCallsQueries'
import { directMessagesKeys, flattenConversationPages } from '../features/directMessages/directMessagesQueries'
import { IncomingCallModal } from '../features/voice/IncomingCallModal'
import { useAuth } from '../hooks/useAuth'
import { showDesktopNotification } from '../lib/desktopNotifications'
import { navigateTo } from '../lib/navigation'
import { getPreferredDeviceId } from '../lib/voiceDevicePreferences'
import { VoiceCallContext } from './VoiceCallContext'

const RING_TIMEOUT_MS = 45000

const IS_SCREEN_SHARE_SUPPORTED = typeof navigator !== 'undefined' && Boolean(navigator.mediaDevices?.getDisplayMedia)

export function VoiceCallProvider({ children }) {
  const { isAuthenticated } = useAuth()
  const queryClient = useQueryClient()
  const hubRef = useRef(null)
  const dmHubRef = useRef(null)
  const roomRef = useRef(null)
  const activeCallRef = useRef(null)
  const audioContainerRef = useRef(null)
  const audioElsRef = useRef(new Map())

  const [activeCall, setActiveCall] = useState(null)
  const [room, setRoom] = useState(null)
  const [participants, setParticipants] = useState({})
  const [isConnecting, setIsConnecting] = useState(false)
  const [isMuted, setIsMuted] = useState(false)
  const [isDeafened, setIsDeafened] = useState(false)
  const [isVideoEnabled, setIsVideoEnabled] = useState(false)
  const [isScreenSharing, setIsScreenSharing] = useState(false)
  const [isReconnecting, setIsReconnecting] = useState(false)
  const [activeSpeakers, setActiveSpeakers] = useState(() => new Set())
  const [participantVolumes, setParticipantVolumes] = useState({})

  const [incomingCall, setIncomingCall] = useState(null)
  const [outgoingCall, setOutgoingCall] = useState(null)
  const incomingCallRef = useRef(null)
  const outgoingCallRef = useRef(null)
  const ringTimeoutRef = useRef(null)
  const connectRoomAsyncRef = useRef(null)

  const isDeafenedRef = useRef(false)
  const participantVolumesRef = useRef({})

  useEffect(() => {
    activeCallRef.current = activeCall
  }, [activeCall])

  useEffect(() => {
    incomingCallRef.current = incomingCall
  }, [incomingCall])

  useEffect(() => {
    outgoingCallRef.current = outgoingCall
  }, [outgoingCall])

  const detachAllAudio = useCallback(() => {
    for (const el of audioElsRef.current.values()) {
      el.pause()
      el.srcObject = null
      el.remove()
    }
    audioElsRef.current.clear()
  }, [])

  const resetCallState = useCallback(() => {
    roomRef.current = null
    detachAllAudio()
    setRoom(null)
    setActiveCall(null)
    setParticipants({})
    setIsMuted(false)
    setIsDeafened(false)
    setIsVideoEnabled(false)
    setIsScreenSharing(false)
    setIsReconnecting(false)
    setActiveSpeakers(new Set())
    isDeafenedRef.current = false
    participantVolumesRef.current = {}
    setParticipantVolumes({})
  }, [detachAllAudio])

  const clearRingTimeout = useCallback(() => {
    if (ringTimeoutRef.current) {
      clearTimeout(ringTimeoutRef.current)
      ringTimeoutRef.current = null
    }
  }, [])

  const leaveCallInternal = useCallback(async () => {
    const call = activeCallRef.current
    const currentRoom = roomRef.current
    roomRef.current = null

    if (currentRoom) {
      try {
        await currentRoom.disconnect()
      } catch (error) {
        console.error('Failed to disconnect the voice room', error)
      }
    }
    if (call?.kind === 'channel') {
      try {
        await hubRef.current?.leaveChannel(call.channelId)
      } catch (error) {
        console.error('Failed to leave the voice hub group', error)
      }
    }
    if (call?.kind === 'dm' && call.callId) {
      directCallsService.endCall(call.conversationId, call.callId).catch((error) => {
        console.error('Failed to end the call', error)
      })
    }
    resetCallState()
  }, [resetCallState])

  useEffect(() => {
    if (!isAuthenticated) return undefined

    const hub = createVoiceHub()
    hubRef.current = hub

    const unsubscribeJoined = hub.onParticipantJoined((event) => {
      const call = activeCallRef.current
      if (!event?.userId || call?.kind !== 'channel' || event.channelId !== call.channelId) return
      setParticipants((current) => ({
        ...current,
        [event.userId]: current[event.userId] ?? {
          UserId: event.userId,
          Identity: event.userId,
          JoinedAt: new Date().toISOString(),
        },
      }))
    })
    const unsubscribeLeft = hub.onParticipantLeft((event) => {
      const call = activeCallRef.current
      if (!event?.userId || call?.kind !== 'channel' || event.channelId !== call.channelId) return
      setParticipants((current) => {
        if (!(event.userId in current)) return current
        const next = { ...current }
        delete next[event.userId]
        return next
      })
    })

    hub.start().catch((error) => {
      console.error('Failed to connect to the voice hub', error)
    })

    return () => {
      unsubscribeJoined()
      unsubscribeLeft()
      hubRef.current = null
      hub.stop().catch(() => {})
      roomRef.current?.disconnect().catch(() => {})
      resetCallState()
    }
  }, [isAuthenticated, resetCallState])

  const describeOtherUser = useCallback(
    (conversationId) => {
      const cached = queryClient.getQueryData(directMessagesKeys.conversations())
      const conversation = flattenConversationPages(cached?.pages).find((item) => item.Id === conversationId)
      const otherUser = conversation?.OtherUser
      return {
        name: otherUser?.Username || [otherUser?.Name, otherUser?.Surname].filter(Boolean).join(' ') || 'Someone',
        avatarUrl: otherUser?.AvatarUrl ?? undefined,
      }
    },
    [queryClient],
  )

  useEffect(() => {
    if (!isAuthenticated) return undefined

    const dmHub = createDirectMessagesHub()
    dmHubRef.current = dmHub

    const unsubscribeJoined = dmHub.onDirectCallParticipantJoined((event) => {
      if (!event?.userId || !event?.conversationId) return

      const call = activeCallRef.current
      if (call?.kind === 'dm' && call.conversationId === event.conversationId) {
        setParticipants((current) => ({
          ...current,
          [event.userId]: current[event.userId] ?? {
            UserId: event.userId,
            Identity: event.userId,
            JoinedAt: new Date().toISOString(),
          },
        }))
      }
    })

    const unsubscribeLeft = dmHub.onDirectCallParticipantLeft((event) => {
      const call = activeCallRef.current
      if (!event?.userId || call?.kind !== 'dm' || call.conversationId !== event.conversationId) return
      setParticipants((current) => {
        if (!(event.userId in current)) return current
        const next = { ...current }
        delete next[event.userId]
        return next
      })
    })

    const unsubscribeInitiated = dmHub.onDirectCallInitiated((call) => {
      if (!call?.Id) return
      const { name, avatarUrl } = describeOtherUser(call.ConversationId)
      setIncomingCall({
        callId: call.Id,
        conversationId: call.ConversationId,
        callerId: call.InitiatorId,
        type: call.Type,
        callerDisplayName: name,
        callerAvatarUrl: avatarUrl,
      })
      showDesktopNotification({
        title: name,
        body: i18n.t(call.Type === 'Video' ? 'calls.incomingVideoCall' : 'calls.incomingVoiceCall'),
        icon: avatarUrl,
        onClick: () => navigateTo(`/cabinet/dm/${call.ConversationId}`),
      })
    })

    const unsubscribeAccepted = dmHub.onDirectCallAccepted((call) => {
      setOutgoingCall((current) => {
        if (current?.callId !== call?.Id) return current
        clearRingTimeout()
        connectRoomAsyncRef.current?.(
          { kind: 'dm', conversationId: current.conversationId, callId: current.callId },
          () => directVoiceService.getDirectVoiceToken(current.conversationId),
          () => directVoiceService.getDirectVoiceParticipants(current.conversationId),
          null,
          current.type === 'Video',
        )
        return null
      })
    })

    const unsubscribeDeclined = dmHub.onDirectCallDeclined((call) => {
      setOutgoingCall((current) => {
        if (current?.callId !== call?.Id) return current
        clearRingTimeout()
        toast({ variant: 'warning', description: i18n.t('calls.callDeclined') })
        return null
      })
    })

    const unsubscribeEnded = dmHub.onDirectCallEnded((call) => {
      if (!call?.Id) return

      setIncomingCall((current) => (current?.callId === call.Id ? null : current))

      setOutgoingCall((current) => {
        if (current?.callId !== call.Id) return current
        clearRingTimeout()
        return null
      })

      const active = activeCallRef.current
      if (active?.kind === 'dm' && active.callId === call.Id && roomRef.current) {
        leaveCallInternal()
      }

      queryClient.invalidateQueries({ queryKey: directCallsKeys.list(call.ConversationId) })
    })

    dmHub.start().catch((error) => {
      console.error('Failed to connect to the DM voice hub', error)
    })

    return () => {
      unsubscribeJoined()
      unsubscribeLeft()
      unsubscribeInitiated()
      unsubscribeAccepted()
      unsubscribeDeclined()
      unsubscribeEnded()
      dmHubRef.current = null
      dmHub.stop().catch(() => {})
    }
  }, [isAuthenticated, queryClient, describeOtherUser, clearRingTimeout, leaveCallInternal])

  const attachAudioTrack = useCallback((track) => {
    if (track.kind !== Track.Kind.Audio) return
    const el = track.attach()
    el.autoplay = true
    audioContainerRef.current?.appendChild(el)
    audioElsRef.current.set(track.sid, el)
  }, [])

  const detachAudioTrack = useCallback((track) => {
    if (track.kind !== Track.Kind.Audio) return
    const el = audioElsRef.current.get(track.sid)
    if (el) {
      track.detach(el)
      el.remove()
      audioElsRef.current.delete(track.sid)
    }
  }, [])

  const connectRoomAsync = useCallback(async (nextCall, getToken, getParticipants, hubJoinAsync, initialVideo = false) => {
    setIsConnecting(true)
    let token
    try {
      token = await getToken()
    } catch (error) {
      console.error('Failed to get a voice token', error)
      toast({ variant: 'danger', title: "Couldn't join the call", description: mapGetVoiceTokenError(error) })
      setIsConnecting(false)
      return
    }

    const newRoom = new Room()

    newRoom.once(RoomEvent.Disconnected, (reason) => {
      if (roomRef.current !== newRoom) return
      const wasIntentional = reason === undefined || reason === DisconnectReason.CLIENT_INITIATED
      resetCallState()
      if (!wasIntentional) {
        toast({ variant: 'warning', title: 'Call ended', description: mapInvoluntaryDisconnectMessage() })
      }
    })

    newRoom.on(RoomEvent.Reconnecting, () => setIsReconnecting(true))
    newRoom.on(RoomEvent.Reconnected, () => setIsReconnecting(false))

    newRoom.on(RoomEvent.ActiveSpeakersChanged, (speakers) => {
      setActiveSpeakers(new Set(speakers.map((speaker) => speaker.identity)))
    })

    newRoom.on(RoomEvent.TrackSubscribed, (track, _publication, participant) => {
      attachAudioTrack(track)
      if (track.kind === Track.Kind.Audio && typeof track.setVolume === 'function') {
        const desired = isDeafenedRef.current ? 0 : (participantVolumesRef.current[participant.identity] ?? 1)
        track.setVolume(desired)
      }
    })
    newRoom.on(RoomEvent.TrackUnsubscribed, (track) => detachAudioTrack(track))

    newRoom.on(RoomEvent.ParticipantConnected, (participant) => {
      setParticipants((current) => ({
        ...current,
        [participant.identity]: current[participant.identity] ?? {
          UserId: participant.identity,
          Identity: participant.identity,
          JoinedAt: new Date().toISOString(),
        },
      }))
    })
    newRoom.on(RoomEvent.ParticipantDisconnected, (participant) => {
      setParticipants((current) => {
        if (!(participant.identity in current)) return current
        const next = { ...current }
        delete next[participant.identity]
        return next
      })
    })

    try {
      await newRoom.connect(token.Url, token.Token)
    } catch (error) {
      console.error('Failed to connect to the LiveKit room', error)
      toast({ variant: 'danger', title: "Couldn't join the call", description: mapVoiceConnectError() })
      setIsConnecting(false)
      return
    }

    roomRef.current = newRoom
    setRoom(newRoom)

    const preferredMicId = getPreferredDeviceId('audioinput') ?? undefined
    const preferredCameraId = getPreferredDeviceId('videoinput') ?? undefined

    try {
      await newRoom.localParticipant.setMicrophoneEnabled(true, { deviceId: preferredMicId })
    } catch (error) {
      console.error('Failed to enable the microphone', error)
    }

    if (initialVideo) {
      try {
        await newRoom.localParticipant.setCameraEnabled(true, { deviceId: preferredCameraId })
        setIsVideoEnabled(true)
      } catch (error) {
        console.error('Failed to enable the camera', error)
      }
    }

    if (hubJoinAsync) {
      hubJoinAsync().catch((error) => {
        console.error('Failed to join the voice hub group', error)
      })
    }

    let seed = []
    try {
      seed = await getParticipants()
    } catch (error) {
      console.error('Failed to load voice participants', error)
    }
    setParticipants((current) => {
      const seededMap = { ...current }
      for (const item of seed) {
        if (item?.UserId) seededMap[item.UserId] = { ...item, ...seededMap[item.UserId] }
      }
      return seededMap
    })
    setActiveCall(nextCall)
    setIsConnecting(false)
  }, [resetCallState, attachAudioTrack, detachAudioTrack])

  useEffect(() => {
    connectRoomAsyncRef.current = connectRoomAsync
  }, [connectRoomAsync])

  const joinCall = useCallback(
    async (serverId, channelId) => {
      const current = activeCallRef.current
      if (current?.kind === 'channel' && current.channelId === channelId) return
      if (current) await leaveCallInternal()

      await connectRoomAsync(
        { kind: 'channel', serverId, channelId },
        () => voiceService.getVoiceToken(channelId),
        () => voiceService.getVoiceParticipants(channelId),
        () => hubRef.current?.joinChannel(channelId),
      )
    },
    [leaveCallInternal, connectRoomAsync],
  )

  const startDmCall = useCallback(
    async (conversationId, type) => {
      const current = activeCallRef.current
      if (current) await leaveCallInternal()
      if (outgoingCallRef.current || incomingCallRef.current) return

      let call
      try {
        call = await directCallsService.startCall(conversationId, type)
      } catch (error) {
        console.error('Failed to start the call', error)
        toast({ variant: 'danger', title: "Couldn't start the call", description: mapStartCallError(error) })
        return
      }

      setOutgoingCall({ callId: call.Id, conversationId, type })
      clearRingTimeout()
      ringTimeoutRef.current = setTimeout(() => {
        setOutgoingCall((current) => {
          if (current?.callId !== call.Id) return current
          directCallsService.endCall(conversationId, call.Id).catch(() => {})
          toast({ variant: 'warning', description: i18n.t('calls.callEnded') })
          return null
        })
      }, RING_TIMEOUT_MS)
    },
    [leaveCallInternal, clearRingTimeout],
  )

  const acceptIncomingCall = useCallback(async () => {
    const call = incomingCallRef.current
    if (!call) return
    setIncomingCall(null)

    try {
      await directCallsService.acceptCall(call.conversationId, call.callId)
    } catch (error) {
      console.error('Failed to accept the call', error)
      toast({ variant: 'danger', title: "Couldn't accept the call", description: mapCallActionError(error) })
      return
    }

    await connectRoomAsync(
      { kind: 'dm', conversationId: call.conversationId, callId: call.callId },
      () => directVoiceService.getDirectVoiceToken(call.conversationId),
      () => directVoiceService.getDirectVoiceParticipants(call.conversationId),
      null,
      call.type === 'Video',
    )
  }, [connectRoomAsync])

  const declineIncomingCall = useCallback(async () => {
    const call = incomingCallRef.current
    if (!call) return
    setIncomingCall(null)
    try {
      await directCallsService.declineCall(call.conversationId, call.callId)
    } catch (error) {
      console.error('Failed to decline the call', error)
    }
  }, [])

  const cancelOutgoingCall = useCallback(async () => {
    const call = outgoingCallRef.current
    if (!call) return
    clearRingTimeout()
    setOutgoingCall(null)
    try {
      await directCallsService.endCall(call.conversationId, call.callId)
    } catch (error) {
      console.error('Failed to cancel the call', error)
    }
  }, [clearRingTimeout])

  const leaveCall = useCallback(async () => {
    if (!activeCallRef.current) return
    await leaveCallInternal()
  }, [leaveCallInternal])

  const toggleMute = useCallback(() => {
    setIsMuted((current) => {
      const next = !current
      roomRef.current?.localParticipant.setMicrophoneEnabled(!next).catch((error) => {
        console.error('Failed to toggle the microphone', error)
      })
      return next
    })
  }, [])

  const toggleDeafen = useCallback(() => {
    setIsDeafened((current) => {
      const next = !current
      isDeafenedRef.current = next
      const currentRoom = roomRef.current
      if (currentRoom) {
        currentRoom.remoteParticipants.forEach((participant) => {
          const volume = next ? 0 : (participantVolumesRef.current[participant.identity] ?? 1)
          participant.audioTrackPublications.forEach((publication) => {
            const track = publication.track
            if (track && typeof track.setVolume === 'function') {
              track.setVolume(volume)
            }
          })
        })
      }
      return next
    })
  }, [])

  const setParticipantVolume = useCallback((userId, volume) => {
    participantVolumesRef.current = { ...participantVolumesRef.current, [userId]: volume }
    setParticipantVolumes(participantVolumesRef.current)

    const participant = roomRef.current?.getParticipantByIdentity(userId)
    if (!participant) return
    const effectiveVolume = isDeafenedRef.current ? 0 : volume
    participant.audioTrackPublications.forEach((publication) => {
      if (publication.track && typeof publication.track.setVolume === 'function') {
        publication.track.setVolume(effectiveVolume)
      }
    })
  }, [])

  const toggleVideo = useCallback(() => {
    setIsVideoEnabled((current) => {
      const next = !current
      const options = next ? { deviceId: getPreferredDeviceId('videoinput') ?? undefined } : undefined
      roomRef.current?.localParticipant.setCameraEnabled(next, options).catch((error) => {
        console.error('Failed to toggle the camera', error)
        setIsVideoEnabled(current)
      })
      return next
    })
  }, [])

  const toggleScreenShare = useCallback(() => {
    if (!IS_SCREEN_SHARE_SUPPORTED) {
      toast({
        variant: 'danger',
        title: i18n.t('voice.screenShareUnsupportedTitle'),
        description: i18n.t('voice.screenShareUnsupportedDescription'),
      })
      return
    }

    setIsScreenSharing((current) => {
      const next = !current
      roomRef.current?.localParticipant.setScreenShareEnabled(next).catch((error) => {
        console.error('Failed to toggle screen sharing', error)
        setIsScreenSharing(current)
      })
      return next
    })
  }, [])

  return (
    <VoiceCallContext.Provider
      value={{
        activeCall,
        incomingCall,
        outgoingCall,
        room,
        participants,
        isConnecting,
        isMuted,
        isDeafened,
        isVideoEnabled,
        isScreenSharing,
        isScreenShareSupported: IS_SCREEN_SHARE_SUPPORTED,
        isReconnecting,
        activeSpeakers,
        participantVolumes,
        joinCall,
        startDmCall,
        acceptIncomingCall,
        declineIncomingCall,
        cancelOutgoingCall,
        leaveCall,
        toggleMute,
        toggleDeafen,
        toggleVideo,
        toggleScreenShare,
        setParticipantVolume,
      }}
    >
      {children}
      <IncomingCallModal incomingCall={incomingCall} onAccept={acceptIncomingCall} onDecline={declineIncomingCall} />
      <div ref={audioContainerRef} style={{ display: 'none' }} aria-hidden="true" />
    </VoiceCallContext.Provider>
  )
}
