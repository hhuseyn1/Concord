// Synthesized rather than a bundled audio file - matches the existing tone-generation pattern in
// VoiceVideoSettingsSection.jsx's speaker test, and avoids shipping/fetching a binary asset for one
// short "ding".
let audioContext

function getAudioContext() {
  const AudioContextCtor = window.AudioContext || window.webkitAudioContext
  if (!AudioContextCtor) return null
  audioContext ??= new AudioContextCtor()
  return audioContext
}

export function playNotificationSound() {
  const context = getAudioContext()
  if (!context) return
  if (context.state === 'suspended') context.resume().catch(() => {})

  const now = context.currentTime
  // Two-note "pop" - a short low note immediately followed by a higher one, each with its own
  // quick attack/decay envelope so it reads as a soft chime instead of a flat beep.
  const notes = [
    { frequency: 740, start: 0, duration: 0.09 },
    { frequency: 988, start: 0.08, duration: 0.14 },
  ]

  for (const note of notes) {
    const oscillator = context.createOscillator()
    const gain = context.createGain()
    oscillator.type = 'sine'
    oscillator.frequency.value = note.frequency
    oscillator.connect(gain)
    gain.connect(context.destination)

    const startTime = now + note.start
    const endTime = startTime + note.duration
    gain.gain.setValueAtTime(0, startTime)
    gain.gain.linearRampToValueAtTime(0.18, startTime + 0.015)
    gain.gain.exponentialRampToValueAtTime(0.001, endTime)

    oscillator.start(startTime)
    oscillator.stop(endTime + 0.02)
  }
}
