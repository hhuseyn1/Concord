let audioContext = null
let stopFn = null

function getAudioContext() {
  if (!audioContext) {
    const Ctor = window.AudioContext || window.webkitAudioContext
    if (!Ctor) return null
    audioContext = new Ctor()
  }
  return audioContext
}

export function startRingtone() {
  if (stopFn) return
  const ctx = getAudioContext()
  if (!ctx) return

  let cancelled = false
  const playBurst = () => {
    if (cancelled) return
    const now = ctx.currentTime
    ;[880, 1108.73].forEach((frequency, index) => {
      const oscillator = ctx.createOscillator()
      const gain = ctx.createGain()
      oscillator.type = 'sine'
      oscillator.frequency.value = frequency
      const start = now + index * 0.25
      gain.gain.setValueAtTime(0, start)
      gain.gain.linearRampToValueAtTime(0.15, start + 0.02)
      gain.gain.linearRampToValueAtTime(0, start + 0.22)
      oscillator.connect(gain)
      gain.connect(ctx.destination)
      oscillator.start(start)
      oscillator.stop(start + 0.25)
    })
  }

  playBurst()
  const intervalId = setInterval(playBurst, 2000)
  stopFn = () => {
    cancelled = true
    clearInterval(intervalId)
    stopFn = null
  }
}

export function stopRingtone() {
  stopFn?.()
}
