import { useCallback, useEffect, useState } from 'react'

export function useMediaDevices() {
  const [devices, setDevices] = useState({ audioinput: [], audiooutput: [], videoinput: [] })
  const [permissionState, setPermissionState] = useState('idle')

  const refreshDevices = useCallback(async () => {
    if (!navigator.mediaDevices?.enumerateDevices) return
    try {
      const list = await navigator.mediaDevices.enumerateDevices()
      setDevices({
        audioinput: list.filter((device) => device.kind === 'audioinput'),
        audiooutput: list.filter((device) => device.kind === 'audiooutput'),
        videoinput: list.filter((device) => device.kind === 'videoinput'),
      })
    } catch (error) {
      console.error('Failed to enumerate media devices', error)
    }
  }, [])

  const requestPermission = useCallback(async () => {
    if (!navigator.mediaDevices?.getUserMedia) {
      setPermissionState('unavailable')
      return
    }
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true, video: true })
      for (const track of stream.getTracks()) track.stop()
      setPermissionState('granted')
      await refreshDevices()
    } catch (error) {
      setPermissionState(error?.name === 'NotFoundError' ? 'unavailable' : 'denied')
    }
  }, [refreshDevices])

  useEffect(() => {
    if (!navigator.mediaDevices) return undefined
    refreshDevices()
    navigator.mediaDevices.addEventListener('devicechange', refreshDevices)
    return () => navigator.mediaDevices.removeEventListener('devicechange', refreshDevices)
  }, [refreshDevices])

  return { devices, permissionState, requestPermission }
}
