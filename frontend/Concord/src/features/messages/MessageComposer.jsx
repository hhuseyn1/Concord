import { AlertTriangle, CornerUpLeft, FileText, Paperclip, SendHorizontal, X } from 'lucide-react'
import { useMemo, useRef, useState } from 'react'
import * as filesService from '../../api/filesService'
import { IconButton } from '../../components/ui/IconButton'
import { Spinner } from '../../components/ui/Spinner'
import { Textarea } from '../../components/ui/Textarea'
import { Tooltip } from '../../components/ui/Tooltip'
import { toast } from '../../components/ui/Toast'
import { useAuth } from '../../hooks/useAuth'
import { cn } from '../../lib/cn'
import { flattenServerMemberPages, useServerMembers } from '../servers/serversQueries'
import { mapAttachmentUploadError, mapSendMessageError } from './messagesErrors'
import { MentionAutocomplete } from './MentionAutocomplete'
import { useSendMessageMutation } from './messagesQueries'
import { useMentionAutocomplete } from './useMentionAutocomplete'
import { clearDraft, readDraft, useDraftPersistence } from './useDraftPersistence'

const MAX_CONTENT_LENGTH = 4000
const WARN_THRESHOLD = MAX_CONTENT_LENGTH - 200
const ACCEPTED_ATTACHMENT_TYPES = '.png,.jpg,.jpeg,.webp,.gif,.mp4,.mp3,.ogg,.pdf,.txt,.zip'
const TYPING_NOTIFY_THROTTLE_MS = 3000

export function MessageComposer({ serverId, channelId, onSent, onTyping, onStopTyping, replyingTo, onCancelReply }) {
  const draftKey = channelId ? `channel:${channelId}` : undefined
  const [content, setContent] = useState(() => readDraft(draftKey))
  useDraftPersistence(draftKey, content)
  const [pendingAttachment, setPendingAttachment] = useState(null)
  const [rateLimitedHint, setRateLimitedHint] = useState(false)
  const [isDraggingOver, setIsDraggingOver] = useState(false)
  const fileInputRef = useRef(null)
  const textareaRef = useRef(null)
  const uploadTokenRef = useRef(0)
  const lastTypingNotifyRef = useRef(0)
  const dragCounterRef = useRef(0)

  const sendMutation = useSendMessageMutation(serverId, channelId)

  const { user } = useAuth()
  const { data: memberPages } = useServerMembers(serverId)
  const mentionCandidates = useMemo(
    () =>
      flattenServerMemberPages(memberPages?.pages)
        .map((member) => member.User)
        .filter((candidate) => candidate?.Id && candidate.Id !== user?.Id),
    [memberPages, user?.Id],
  )
  const mention = useMentionAutocomplete({ candidates: mentionCandidates, content, setContent, textareaRef })

  const trimmedLength = content.trim().length
  const overLimit = content.length > MAX_CONTENT_LENGTH
  const isUploading = pendingAttachment?.status === 'uploading'
  const hasReadyAttachment = pendingAttachment?.status === 'ready'
  const canSend = (trimmedLength > 0 || hasReadyAttachment) && !overLimit && !isUploading && !sendMutation.isPending

  const handleContentChange = (event) => {
    setContent(event.target.value)
    mention.handleChange(event.target.value, event.target.selectionStart)
    if (rateLimitedHint) setRateLimitedHint(false)

    const now = Date.now()
    if (onTyping && event.target.value.trim() && now - lastTypingNotifyRef.current > TYPING_NOTIFY_THROTTLE_MS) {
      lastTypingNotifyRef.current = now
      onTyping()
    }
  }

  const handleFileButtonClick = () => {
    fileInputRef.current?.click()
  }

  const uploadFile = async (file) => {
    const token = ++uploadTokenRef.current
    setPendingAttachment({ status: 'uploading', file, progress: 0 })

    try {
      const { Url } = await filesService.uploadAttachmentWithProgress(file, (progress) => {
        if (uploadTokenRef.current !== token) return
        setPendingAttachment((current) => (current?.status === 'uploading' ? { ...current, progress } : current))
      })
      if (uploadTokenRef.current !== token) return
      setPendingAttachment({ status: 'ready', file, url: Url })
    } catch (error) {
      if (uploadTokenRef.current !== token) return
      setPendingAttachment(null)
      toast({ variant: 'danger', title: 'Could not attach file', description: mapAttachmentUploadError(error) })
    }
  }

  const handleFileChange = (event) => {
    const file = event.target.files?.[0]
    event.target.value = ''
    if (file) uploadFile(file)
  }

  const handlePaste = (event) => {
    const file = Array.from(event.clipboardData?.files ?? []).find((item) => item.type.startsWith('image/'))
    if (!file) return
    event.preventDefault()
    uploadFile(file)
  }

  const handleRemoveAttachment = () => {
    uploadTokenRef.current++
    setPendingAttachment(null)
  }

  const handleDragEnter = (event) => {
    event.preventDefault()
    dragCounterRef.current++
    if (event.dataTransfer.types.includes('Files')) setIsDraggingOver(true)
  }

  const handleDragOver = (event) => {
    event.preventDefault()
  }

  const handleDragLeave = (event) => {
    event.preventDefault()
    dragCounterRef.current = Math.max(0, dragCounterRef.current - 1)
    if (dragCounterRef.current === 0) setIsDraggingOver(false)
  }

  const handleDrop = (event) => {
    event.preventDefault()
    dragCounterRef.current = 0
    setIsDraggingOver(false)
    const file = event.dataTransfer.files?.[0]
    if (file) uploadFile(file)
  }

  const handleSend = async () => {
    if (!canSend) return
    const trimmed = content.trim()

    try {
      await sendMutation.mutateAsync({
        Content: trimmed,
        AttachmentUrl: pendingAttachment?.status === 'ready' ? pendingAttachment.url : null,
        ReplyToMessageId: replyingTo?.Id ?? null,
      })
      setContent('')
      clearDraft(draftKey)
      setPendingAttachment(null)
      setRateLimitedHint(false)
      onCancelReply?.()
      onSent?.()
      onStopTyping?.()
    } catch (error) {
      if (error?.isRateLimited) {
        setRateLimitedHint(true)
        return
      }
      toast({ variant: 'danger', title: 'Could not send message', description: mapSendMessageError(error) })
    }
  }

  const handleKeyDown = (event) => {
    if (mention.handleKeyDown(event)) return

    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      handleSend()
    } else if (event.key === 'Escape' && replyingTo) {
      event.preventDefault()
      onCancelReply?.()
    }
  }

  const replyToSenderName =
    replyingTo &&
    (replyingTo.Sender?.Username ||
      [replyingTo.Sender?.Name, replyingTo.Sender?.Surname].filter(Boolean).join(' ') ||
      'Unknown user')

  return (
    <div
      className="relative shrink-0 px-4 pt-2 pb-4"
      onDragEnter={handleDragEnter}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
    >
      {isDraggingOver && (
        <div className="pointer-events-none absolute inset-x-4 inset-y-1 z-10 flex items-center justify-center rounded-md border-2 border-dashed border-brand bg-brand-bg/90 text-sm font-medium text-brand">
          Drop a file to attach it
        </div>
      )}
      {replyingTo && (
        <div className="mb-2 flex items-center gap-2 rounded-md border border-border-default bg-surface-sidebar px-3 py-2 text-sm">
          <CornerUpLeft className="size-4 shrink-0 text-fg-muted" aria-hidden="true" />
          <span className="min-w-0 flex-1 truncate text-fg-muted">
            Replying to <span className="font-medium text-fg-default">{replyToSenderName}</span>
          </span>
          <IconButton aria-label="Cancel reply" size="sm" variant="ghost" onClick={onCancelReply}>
            <X className="size-3.5" aria-hidden="true" />
          </IconButton>
        </div>
      )}
      {pendingAttachment && (
        <div className="mb-2 flex items-center gap-2 rounded-md border border-border-default bg-surface-sidebar px-3 py-2 text-sm">
          {pendingAttachment.status === 'uploading' ? (
            <Spinner size="sm" />
          ) : (
            <FileText className="size-4 shrink-0 text-fg-muted" aria-hidden="true" />
          )}
          <span className="min-w-0 flex-1 truncate text-fg-default">{pendingAttachment.file.name}</span>
          <span className="shrink-0 text-xs text-fg-muted">
            {pendingAttachment.status === 'uploading' ? `Uploading… ${pendingAttachment.progress ?? 0}%` : 'Ready to send'}
          </span>
          <Tooltip content="Remove attachment">
            <IconButton
              aria-label="Remove attachment"
              size="sm"
              variant="ghost"
              onClick={handleRemoveAttachment}
            >
              <X className="size-3.5" aria-hidden="true" />
            </IconButton>
          </Tooltip>
        </div>
      )}

      <div className="relative flex items-end gap-2 rounded-md border border-border-default bg-surface-sidebar px-2 py-1.5 focus-within:border-brand">
        {mention.isOpen && (
          <MentionAutocomplete suggestions={mention.suggestions} activeIndex={mention.activeIndex} onSelect={mention.handleSelect} />
        )}
        <Tooltip content="Attach a file">
          <IconButton
            aria-label="Attach a file"
            variant="ghost"
            onClick={handleFileButtonClick}
            disabled={sendMutation.isPending}
          >
            <Paperclip className="size-4" aria-hidden="true" />
          </IconButton>
        </Tooltip>
        <input
          ref={fileInputRef}
          type="file"
          accept={ACCEPTED_ATTACHMENT_TYPES}
          className="hidden"
          onChange={handleFileChange}
        />

        <Textarea
          ref={textareaRef}
          value={content}
          onChange={handleContentChange}
          onKeyDown={handleKeyDown}
          onPaste={handlePaste}
          placeholder="Message this channel…"
          rows={1}
          disabled={sendMutation.isPending}
          invalid={overLimit}
          className="min-h-0 flex-1 resize-none border-none bg-transparent px-1 py-1.5 focus-visible:ring-0"
        />

        <Tooltip content="Send">
          <IconButton
            aria-label="Send message"
            variant="primary"
            disabled={!canSend}
            onClick={handleSend}
          >
            {sendMutation.isPending ? <Spinner size="sm" /> : <SendHorizontal className="size-4" aria-hidden="true" />}
          </IconButton>
        </Tooltip>
      </div>

      <div className="flex items-center justify-between px-1 pt-1">
        <div>
          {rateLimitedHint && (
            <p className="flex items-center gap-1.5 text-xs text-warning">
              <AlertTriangle className="size-3.5 shrink-0" aria-hidden="true" />
              You&apos;re sending messages too fast. Wait a moment and try again.
            </p>
          )}
          {!rateLimitedHint && overLimit && (
            <p className="flex items-center gap-1.5 text-xs text-danger">
              <AlertTriangle className="size-3.5 shrink-0" aria-hidden="true" />
              Message is too long — trim it to {MAX_CONTENT_LENGTH} characters or fewer to send.
            </p>
          )}
        </div>
        {content.length > WARN_THRESHOLD && (
          <p className={cn('text-xs', overLimit ? 'text-danger' : 'text-fg-muted')}>
            {content.length}/{MAX_CONTENT_LENGTH}
          </p>
        )}
      </div>
    </div>
  )
}
