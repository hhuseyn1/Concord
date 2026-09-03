import { FileText } from 'lucide-react'
import { getApiBaseUrl } from '../../api/httpClient'

const IMAGE_EXTENSIONS = ['png', 'jpg', 'jpeg', 'webp', 'gif']
const VIDEO_EXTENSIONS = ['mp4']
const AUDIO_EXTENSIONS = ['mp3', 'ogg']

function getFilename(url) {
  return url.split('/').pop() || 'attachment'
}

function getExtension(url) {
  const filename = getFilename(url.split('?')[0])
  const dot = filename.lastIndexOf('.')
  return dot >= 0 ? filename.slice(dot + 1).toLowerCase() : ''
}

export function MessageAttachment({ url }) {
  if (!url) return null

  const absoluteUrl = `${getApiBaseUrl()}${url}`
  const extension = getExtension(url)
  const filename = getFilename(url)

  if (IMAGE_EXTENSIONS.includes(extension)) {
    return (
      <a
        href={absoluteUrl}
        target="_blank"
        rel="noreferrer"
        className="mt-1.5 block max-w-sm overflow-hidden rounded-md border border-border-default"
      >
        <img src={absoluteUrl} alt={filename} className="max-h-80 w-full object-cover" loading="lazy" />
      </a>
    )
  }

  if (VIDEO_EXTENSIONS.includes(extension)) {
    return (
      <video
        src={absoluteUrl}
        controls
        className="mt-1.5 max-h-80 max-w-sm rounded-md border border-border-default"
      />
    )
  }

  if (AUDIO_EXTENSIONS.includes(extension)) {
    return <audio src={absoluteUrl} controls className="mt-1.5 w-full max-w-sm" />
  }

  return (
    <a
      href={absoluteUrl}
      target="_blank"
      rel="noreferrer"
      download
      className="mt-1.5 inline-flex items-center gap-2 rounded-md border border-border-default bg-surface-sidebar px-3 py-2 text-sm text-fg-default transition-colors duration-150 hover:bg-fg-default/5"
    >
      <FileText className="size-4 shrink-0 text-fg-muted" aria-hidden="true" />
      <span className="max-w-64 truncate">{filename}</span>
    </a>
  )
}
