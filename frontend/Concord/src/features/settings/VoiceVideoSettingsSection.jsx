import { AlertTriangle, Mic, Speaker, Video } from 'lucide-react'
import { useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '../../components/ui/Button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuTrigger,
} from '../../components/ui/DropdownMenu'
import { getPreferredDeviceId, setPreferredDeviceId } from '../../lib/voiceDevicePreferences'
import { useMediaDevices } from '../../hooks/useMediaDevices'

function DeviceSelect({ icon: Icon, label, kind, devices, value, onChange }) {
  const { t } = useTranslation()
  const selected = devices.find((device) => device.deviceId === value)

  return (
    <div className="flex items-center justify-between gap-3">
      <div className="flex min-w-0 items-center gap-2">
        <Icon className="size-4 shrink-0 text-fg-muted" aria-hidden="true" />
        <p className="text-sm font-medium text-fg-default">{label}</p>
      </div>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="secondary" size="sm" className="max-w-48 justify-start truncate">
            <span className="truncate">{selected?.label || t('voice.defaultDevice')}</span>
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="max-w-64">
          <DropdownMenuRadioGroup value={value ?? ''} onValueChange={(next) => onChange(next || null)}>
            <DropdownMenuRadioItem value="">{t('voice.defaultDevice')}</DropdownMenuRadioItem>
            {devices.map((device) => (
              <DropdownMenuRadioItem key={device.deviceId || kind} value={device.deviceId}>
                <span className="truncate">{device.label || kind}</span>
              </DropdownMenuRadioItem>
            ))}
          </DropdownMenuRadioGroup>
        </DropdownMenuContent>
      </DropdownMenu>
    </div>
  )
}

export function VoiceVideoSettingsSection() {
  const { t } = useTranslation()
  const { devices, permissionState, requestPermission } = useMediaDevices()
  const [micDeviceId, setMicDeviceId] = useState(() => getPreferredDeviceId('audioinput'))
  const [speakerDeviceId, setSpeakerDeviceId] = useState(() => getPreferredDeviceId('audiooutput'))
  const [cameraDeviceId, setCameraDeviceId] = useState(() => getPreferredDeviceId('videoinput'))
  const [inputLevel, setInputLevel] = useState(0)
  const [previewError, setPreviewError] = useState('')

  const videoRef = useRef(null)
  const streamRef = useRef(null)
  const audioContextRef = useRef(null)
  const rafRef = useRef(null)

  useEffect(() => {
    requestPermission()
  }, [])

  useEffect(() => {
    if (permissionState !== 'granted') return undefined
    let cancelled = false

    const start = async () => {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({
          audio: micDeviceId ? { deviceId: { exact: micDeviceId } } : true,
          video: cameraDeviceId ? { deviceId: { exact: cameraDeviceId } } : true,
        })
        if (cancelled) {
          for (const track of stream.getTracks()) track.stop()
          return
        }
        streamRef.current = stream
        setPreviewError('')

        if (videoRef.current) videoRef.current.srcObject = stream

        const AudioContextCtor = window.AudioContext || window.webkitAudioContext
        const audioContext = new AudioContextCtor()
        audioContextRef.current = audioContext
        const source = audioContext.createMediaStreamSource(stream)
        const analyser = audioContext.createAnalyser()
        analyser.fftSize = 512
        source.connect(analyser)
        const data = new Uint8Array(analyser.frequencyBinCount)

        const tick = () => {
          analyser.getByteFrequencyData(data)
          const average = data.reduce((sum, value) => sum + value, 0) / data.length
          setInputLevel(Math.min(100, Math.round((average / 255) * 140)))
          rafRef.current = requestAnimationFrame(tick)
        }
        tick()
      } catch (error) {
        if (!cancelled) setPreviewError(error?.message || 'Could not access the selected device.')
      }
    }

    start()

    return () => {
      cancelled = true
      if (rafRef.current) cancelAnimationFrame(rafRef.current)
      audioContextRef.current?.close().catch(() => {})
      streamRef.current?.getTracks().forEach((track) => track.stop())
      streamRef.current = null
      setInputLevel(0)
    }
  }, [permissionState, micDeviceId, cameraDeviceId])

  const handleMicChange = (deviceId) => {
    setMicDeviceId(deviceId)
    setPreferredDeviceId('audioinput', deviceId)
  }
  const handleSpeakerChange = (deviceId) => {
    setSpeakerDeviceId(deviceId)
    setPreferredDeviceId('audiooutput', deviceId)
  }
  const handleCameraChange = (deviceId) => {
    setCameraDeviceId(deviceId)
    setPreferredDeviceId('videoinput', deviceId)
  }

  const testSpeaker = async () => {
    try {
      const AudioContextCtor = window.AudioContext || window.webkitAudioContext
      const audioContext = new AudioContextCtor()
      const oscillator = audioContext.createOscillator()
      const gain = audioContext.createGain()
      const destination = audioContext.createMediaStreamDestination()
      oscillator.frequency.value = 440
      gain.gain.setValueAtTime(0.2, audioContext.currentTime)
      oscillator.connect(gain)
      gain.connect(destination)
      gain.connect(audioContext.destination)
      oscillator.start()
      oscillator.stop(audioContext.currentTime + 0.6)

      if (speakerDeviceId && 'setSinkId' in HTMLMediaElement.prototype) {
        const audioEl = new Audio()
        audioEl.srcObject = destination.stream
        await audioEl.setSinkId(speakerDeviceId)
        await audioEl.play()
      }

      setTimeout(() => audioContext.close().catch(() => {}), 800)
    } catch (error) {
      console.error('Speaker test failed', error)
    }
  }

  const supportsSinkId = typeof HTMLMediaElement !== 'undefined' && 'setSinkId' in HTMLMediaElement.prototype

  return (
    <div className="flex max-w-md flex-col gap-6">
      <h2 className="text-sm font-semibold text-fg-heading">{t('voice.title')}</h2>

      {(permissionState === 'denied' || permissionState === 'unavailable') && (
        <div className="flex items-start gap-2 rounded-md border border-warning/40 bg-warning-bg px-3 py-2 text-sm text-warning">
          <AlertTriangle className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
          <p>{permissionState === 'denied' ? t('voice.permissionDenied') : t('voice.noPermissionYet')}</p>
        </div>
      )}

      <div className="flex flex-col gap-4">
        <DeviceSelect
          icon={Mic}
          label={t('voice.microphone')}
          kind="audioinput"
          devices={devices.audioinput}
          value={micDeviceId}
          onChange={handleMicChange}
        />
        {permissionState === 'granted' && (
          <div className="ml-6 h-2 w-full overflow-hidden rounded-full bg-fg-default/10" aria-label={t('voice.inputLevel')}>
            <div
              className="h-full rounded-full bg-success transition-[width] duration-100"
              style={{ width: `${inputLevel}%` }}
            />
          </div>
        )}

        <DeviceSelect
          icon={Speaker}
          label={t('voice.speaker')}
          kind="audiooutput"
          devices={devices.audiooutput}
          value={speakerDeviceId}
          onChange={handleSpeakerChange}
        />
        <Button size="sm" variant="secondary" className="ml-6 w-fit" onClick={testSpeaker} disabled={!supportsSinkId && Boolean(speakerDeviceId)}>
          {t('voice.testSpeaker')}
        </Button>

        <DeviceSelect
          icon={Video}
          label={t('voice.camera')}
          kind="videoinput"
          devices={devices.videoinput}
          value={cameraDeviceId}
          onChange={handleCameraChange}
        />
        {permissionState === 'granted' && (
          <div className="ml-6 aspect-video w-full overflow-hidden rounded-md bg-surface-sidebar">
            <video ref={videoRef} autoPlay muted playsInline className="size-full object-cover" />
          </div>
        )}
        {previewError && <p className="ml-6 text-xs text-danger">{previewError}</p>}
      </div>
    </div>
  )
}
