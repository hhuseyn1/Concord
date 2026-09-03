const KEYS = {
  audioinput: 'concord.voice.micDeviceId',
  audiooutput: 'concord.voice.speakerDeviceId',
  videoinput: 'concord.voice.cameraDeviceId',
}

export function getPreferredDeviceId(kind) {
  try {
    return localStorage.getItem(KEYS[kind])
  } catch {
    return null
  }
}

export function setPreferredDeviceId(kind, deviceId) {
  try {
    if (deviceId) localStorage.setItem(KEYS[kind], deviceId)
    else localStorage.removeItem(KEYS[kind])
  } catch {
  }
}
