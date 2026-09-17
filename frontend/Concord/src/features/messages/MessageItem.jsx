import { useQuery } from '@tanstack/react-query'
import { CheckSquare, Copy, CornerUpLeft, EyeOff, Flag, Forward, Pencil, Pin, PinOff, Reply, SmilePlus, Trash2 } from 'lucide-react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import * as usersService from '../../api/usersService'
import { Avatar } from '../../components/ui/Avatar'
import { Button } from '../../components/ui/Button'
import { IconButton } from '../../components/ui/IconButton'
import { Modal } from '../../components/ui/Modal'
import { Popover, PopoverClose, PopoverContent, PopoverTrigger } from '../../components/ui/Popover'
import { Textarea } from '../../components/ui/Textarea'
import { toast } from '../../components/ui/Toast'
import { Tooltip } from '../../components/ui/Tooltip'
import {
  ContextMenu,
  ContextMenuContent,
  ContextMenuItem,
  ContextMenuSub,
  ContextMenuSubContent,
  ContextMenuSubTrigger,
  ContextMenuTrigger,
} from '../../components/ui/ContextMenu'
import { useAuth } from '../../hooks/useAuth'
import { cn } from '../../lib/cn'
import { ProfilePopover } from '../members/ProfilePopover'
import { ReportModal } from '../moderation/ReportModal'
import { formatAbsoluteTimestamp, formatGroupTimestamp, formatShortTime } from './formatMessageTime'
import { ForwardMessageModal } from './ForwardMessageModal'
import { jumpToMessage } from './jumpToMessage'
import { mapEditMessageError } from './messagesErrors'
import { MessageAttachment } from './MessageAttachment'
import { useMentionedUsers } from './useMentionedUsers'

const MAX_CONTENT_LENGTH = 4000
const REPLY_PREVIEW_MAX_LENGTH = 80

const QUICK_REACTIONS = ['👍', '❤️', '😂', '😮', '😢', '🎉']

export function MessageItem({
  message,
  showHeader,
  isOwn,
  onEdit,
  onDelete,
  onReply,
  replyToMessage,
  onToggleReaction,
  selectionMode = false,
  selected = false,
  onToggleSelect,
  onEnterSelectionMode,
  onPin,
  onUnpin,
  onForward,
  sourceServerId,
  sourceChannelId,
  sourceConversationId,
}) {
  const { t } = useTranslation()
  const { user } = useAuth()
  const [isEditing, setIsEditing] = useState(false)
  const [editValue, setEditValue] = useState(message.Content)
  const [editError, setEditError] = useState('')
  const [isSavingEdit, setIsSavingEdit] = useState(false)
  const [confirmDeleteOpen, setConfirmDeleteOpen] = useState(false)
  const [confirmHideOpen, setConfirmHideOpen] = useState(false)
  const [forwardOpen, setForwardOpen] = useState(false)
  const [reportOpen, setReportOpen] = useState(false)

  const mentionedUsers = useMentionedUsers(message.MentionedUserIds)

  const { data: forwardedFromSender } = useQuery({
    queryKey: ['users', message.ForwardedFromSenderId],
    queryFn: () => usersService.getUserById(message.ForwardedFromSenderId),
    enabled: Boolean(message.ForwardedFromSenderId),
    staleTime: 5 * 60 * 1000,
  })

  const sender = message.Sender
  const senderName = sender?.Username || [sender?.Name, sender?.Surname].filter(Boolean).join(' ') || 'Unknown user'

  const startEdit = () => {
    setEditValue(message.Content)
    setEditError('')
    setIsEditing(true)
  }

  const cancelEdit = () => {
    setIsEditing(false)
    setEditError('')
  }

  const saveEdit = async () => {
    const trimmed = editValue.trim()
    if (!trimmed) {
      setEditError('Message cannot be empty.')
      return
    }
    if (trimmed.length > MAX_CONTENT_LENGTH) {
      setEditError(`Messages can be at most ${MAX_CONTENT_LENGTH} characters.`)
      return
    }
    if (trimmed === message.Content) {
      setIsEditing(false)
      return
    }
    setIsSavingEdit(true)
    try {
      await onEdit(message.Id, trimmed)
      setIsEditing(false)
    } catch (error) {
      setEditError(mapEditMessageError(error))
    } finally {
      setIsSavingEdit(false)
    }
  }

  const handleDeleteAction = () => {
    if (isOwn) {
      setConfirmDeleteOpen(true)
    } else {
      setConfirmHideOpen(true)
    }
  }

  const confirmDelete = () => {
    onDelete(message.Id)
    setConfirmDeleteOpen(false)
  }

  const confirmHide = () => {
    onDelete(message.Id)
    setConfirmHideOpen(false)
  }

  const handleRowClick = () => {
    if (selectionMode) onToggleSelect?.(message.Id)
  }

  const handleCopyText = async () => {
    try {
      await navigator.clipboard.writeText(message.Content ?? '')
      toast({ variant: 'success', description: t('messages.copied') })
    } catch {
      toast({ variant: 'danger', description: 'Could not copy to clipboard.' })
    }
  }

  const handleTogglePin = async () => {
    try {
      if (message.PinnedAt) {
        await onUnpin?.(message.Id)
      } else {
        await onPin?.(message.Id)
      }
    } catch {
    }
  }

  const handleForwardPick = async (target) => {
    setForwardOpen(false)
    try {
      await onForward?.(message.Id, target)
    } catch {
    }
  }

  const renderContent = (content) => {
    if (!content || mentionedUsers.size === 0) return content

    const parts = content.split(/(@[a-zA-Z0-9_]{1,32})/g)
    return parts.map((part, index) => {
      if (!part.startsWith('@')) return part
      const mentioned = mentionedUsers.get(part.slice(1).toLowerCase())
      if (!mentioned) return part

      const mentionName = mentioned.Username || part.slice(1)
      return (
        <ProfilePopover key={`${index}-${part}`} userId={mentioned.Id} side="top" align="start">
          <button
            type="button"
            className="rounded bg-brand-bg px-1 font-medium text-brand hover:underline"
          >
            @{mentionName}
          </button>
        </ProfilePopover>
      )
    })
  }

  const row = (
    <div
      data-message-id={message.Id}
      onClick={selectionMode ? handleRowClick : undefined}
      className={cn(
        'group relative flex gap-3 rounded-md px-4 py-0.5 transition-colors duration-150 hover:bg-fg-default/[0.03] motion-safe:animate-row-in',
        showHeader && 'mt-3 pt-1',
        selectionMode && 'cursor-pointer',
        selected && 'bg-brand-bg/40 hover:bg-brand-bg/40',
      )}
    >
      {selectionMode && (
        <div className="flex w-5 shrink-0 items-start justify-center pt-1.5">
          <input
            type="checkbox"
            checked={selected}
            onChange={() => onToggleSelect?.(message.Id)}
            onClick={(event) => event.stopPropagation()}
            aria-label={selected ? 'Deselect message' : 'Select message'}
            className="size-4 accent-brand"
          />
        </div>
      )}

      <div className="flex w-10 shrink-0 justify-center">
        {showHeader ? (
          <ProfilePopover userId={sender?.Id} side="right" align="start">
            <button
              type="button"
              aria-label={`View ${senderName}'s profile`}
              className="rounded-full focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand"
            >
              <Avatar src={sender?.AvatarUrl ?? undefined} name={senderName} size="md" />
            </button>
          </ProfilePopover>
        ) : (
          <span className="hidden pt-0.5 text-[10px] leading-5 text-fg-muted select-none group-hover:inline">
            {formatShortTime(message.Created)}
          </span>
        )}
      </div>

      <div className="min-w-0 flex-1">
        {showHeader && (
          <div className="flex items-baseline gap-2">
            <ProfilePopover userId={sender?.Id} side="bottom" align="start">
              <button
                type="button"
                className="min-w-0 truncate rounded-sm text-sm font-medium text-fg-default hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand"
              >
                {senderName}
              </button>
            </ProfilePopover>
            <Tooltip content={formatAbsoluteTimestamp(message.Created)}>
              <span className="shrink-0 text-xs text-fg-faint">{formatGroupTimestamp(message.Created)}</span>
            </Tooltip>
          </div>
        )}

        {message.ForwardedFromSenderId && (
          <p className="mb-0.5 flex items-center gap-1.5 text-xs text-fg-muted">
            <Forward className="size-3 shrink-0" aria-hidden="true" />
            {t('messages.forwardedFrom', {
              name:
                forwardedFromSender?.Username ||
                [forwardedFromSender?.Name, forwardedFromSender?.Surname].filter(Boolean).join(' ') ||
                t('common.unknownUser'),
            })}
          </p>
        )}

        {message.ReplyToMessageId && (
          <button
            type="button"
            onClick={() => jumpToMessage(message.ReplyToMessageId)}
            className="mb-0.5 flex max-w-full items-center gap-1.5 text-xs text-fg-muted hover:text-fg-default"
          >
            <CornerUpLeft className="size-3 shrink-0" aria-hidden="true" />
            {replyToMessage ? (
              <>
                <span className="shrink-0 font-medium">
                  {replyToMessage.Sender?.Username ||
                    [replyToMessage.Sender?.Name, replyToMessage.Sender?.Surname].filter(Boolean).join(' ') ||
                    'Unknown user'}
                </span>
                <span className="truncate">
                  {replyToMessage.Content
                    ? replyToMessage.Content.length > REPLY_PREVIEW_MAX_LENGTH
                      ? `${replyToMessage.Content.slice(0, REPLY_PREVIEW_MAX_LENGTH)}…`
                      : replyToMessage.Content
                    : 'Attachment'}
                </span>
              </>
            ) : (
              <span className="italic">Original message</span>
            )}
          </button>
        )}

        {isEditing ? (
          <div className="flex flex-col gap-1.5 py-0.5">
            <Textarea
              autoFocus
              rows={1}
              value={editValue}
              disabled={isSavingEdit}
              invalid={Boolean(editError)}
              onChange={(event) => {
                setEditValue(event.target.value)
                if (editError) setEditError('')
              }}
              onKeyDown={(event) => {
                if (event.key === 'Enter' && !event.shiftKey) {
                  event.preventDefault()
                  saveEdit()
                } else if (event.key === 'Escape') {
                  event.preventDefault()
                  cancelEdit()
                }
              }}
            />
            {editError && <p className="text-xs text-danger">{editError}</p>}
            <div className="flex items-center gap-3 text-xs">
              <button
                type="button"
                className="font-medium text-brand hover:underline disabled:opacity-50"
                disabled={isSavingEdit}
                onClick={saveEdit}
              >
                save
              </button>
              <button
                type="button"
                className="text-fg-muted hover:underline disabled:opacity-50"
                disabled={isSavingEdit}
                onClick={cancelEdit}
              >
                cancel
              </button>
              <span className="text-fg-muted">escape to cancel · enter to save</span>
            </div>
          </div>
        ) : (
          <p className="text-sm break-words whitespace-pre-wrap text-fg-default">
            {renderContent(message.Content)}
            {message.EditedAtUtc && (
              <Tooltip content={formatAbsoluteTimestamp(message.EditedAtUtc)}>
                <span className="ml-1.5 text-[10px] text-fg-muted select-none">(edited)</span>
              </Tooltip>
            )}
            {message.PinnedAt && (
              <Tooltip content={t('messages.pinned')}>
                <Pin className="ml-1.5 inline size-3 text-fg-muted" aria-hidden="true" />
              </Tooltip>
            )}
          </p>
        )}

        <MessageAttachment url={message.AttachmentUrl} />

        {message.Reactions?.length > 0 && (
          <div className="mt-1 flex flex-wrap gap-1">
            {message.Reactions.map(({ Emoji, UserIds }) => {
              const reactedByMe = Boolean(user?.Id) && UserIds.includes(user.Id)
              return (
                <button
                  key={Emoji}
                  type="button"
                  onClick={() => onToggleReaction?.(message.Id, Emoji)}
                  className={cn(
                    'flex items-center gap-1 rounded-full border px-1.5 py-0.5 text-xs transition-colors',
                    reactedByMe
                      ? 'border-brand bg-brand-bg text-brand'
                      : 'border-border-default bg-surface-floating text-fg-muted hover:border-fg-muted',
                  )}
                >
                  <span>{Emoji}</span>
                  <span className="font-medium">{UserIds.length}</span>
                </button>
              )
            })}
          </div>
        )}
      </div>

      {!isEditing && !selectionMode && (
        <div className="absolute top-2 right-3 flex items-center gap-0.5 rounded-md border border-border-default bg-surface-floating p-0.5 opacity-0 shadow-sm pointer-events-none group-hover:opacity-100 group-hover:pointer-events-auto group-focus-within:opacity-100 group-focus-within:pointer-events-auto">
          {onToggleReaction && (
            <Popover>
              <Tooltip content="Add reaction">
                <PopoverTrigger asChild>
                  <IconButton aria-label="Add reaction" size="sm">
                    <SmilePlus className="size-3.5" aria-hidden="true" />
                  </IconButton>
                </PopoverTrigger>
              </Tooltip>
              <PopoverContent side="top" align="end" className="flex w-auto gap-1 p-1.5">
                {QUICK_REACTIONS.map((emoji) => (
                  <PopoverClose asChild key={emoji}>
                    <button
                      type="button"
                      onClick={() => onToggleReaction(message.Id, emoji)}
                      className="rounded-md p-1.5 text-lg transition-colors hover:bg-fg-default/10"
                      aria-label={`React with ${emoji}`}
                    >
                      {emoji}
                    </button>
                  </PopoverClose>
                ))}
              </PopoverContent>
            </Popover>
          )}
          {onReply && (
            <Tooltip content="Reply">
              <IconButton aria-label="Reply to message" size="sm" onClick={() => onReply(message)}>
                <Reply className="size-3.5" aria-hidden="true" />
              </IconButton>
            </Tooltip>
          )}
          {isOwn && (
            <Tooltip content="Edit">
              <IconButton aria-label="Edit message" size="sm" onClick={startEdit}>
                <Pencil className="size-3.5" aria-hidden="true" />
              </IconButton>
            </Tooltip>
          )}
          {message.Content && (
            <Tooltip content={t('messages.copyText')}>
              <IconButton aria-label={t('messages.copyText')} size="sm" onClick={handleCopyText}>
                <Copy className="size-3.5" aria-hidden="true" />
              </IconButton>
            </Tooltip>
          )}
          {(onPin || onUnpin) && (
            <Tooltip content={message.PinnedAt ? t('messages.unpin') : t('messages.pin')}>
              <IconButton
                aria-label={message.PinnedAt ? t('messages.unpin') : t('messages.pin')}
                size="sm"
                onClick={handleTogglePin}
              >
                {message.PinnedAt ? <PinOff className="size-3.5" aria-hidden="true" /> : <Pin className="size-3.5" aria-hidden="true" />}
              </IconButton>
            </Tooltip>
          )}
          {onForward && (
            <Tooltip content={t('messages.forward')}>
              <IconButton aria-label={t('messages.forward')} size="sm" onClick={() => setForwardOpen(true)}>
                <Forward className="size-3.5" aria-hidden="true" />
              </IconButton>
            </Tooltip>
          )}
          <Tooltip content={isOwn ? 'Delete' : 'Hide for me'}>
            <IconButton
              aria-label={isOwn ? 'Delete message' : 'Hide message for me'}
              size="sm"
              onClick={handleDeleteAction}
            >
              {isOwn ? (
                <Trash2 className="size-3.5" aria-hidden="true" />
              ) : (
                <EyeOff className="size-3.5" aria-hidden="true" />
              )}
            </IconButton>
          </Tooltip>
        </div>
      )}
    </div>
  )

  return (
    <>
      <ContextMenu>
        <ContextMenuTrigger asChild>{row}</ContextMenuTrigger>
        <ContextMenuContent>
          {!selectionMode && onReply && (
            <ContextMenuItem onSelect={() => onReply(message)}>
              <Reply className="size-4" aria-hidden="true" />
              Reply
            </ContextMenuItem>
          )}
          {!selectionMode && onToggleReaction && (
            <ContextMenuSub>
              <ContextMenuSubTrigger>
                <SmilePlus className="size-4" aria-hidden="true" />
                Add Reaction
              </ContextMenuSubTrigger>
              <ContextMenuSubContent className="flex w-auto flex-wrap gap-0.5 p-1.5">
                {QUICK_REACTIONS.map((emoji) => (
                  <ContextMenuItem
                    key={emoji}
                    onSelect={() => onToggleReaction(message.Id, emoji)}
                    aria-label={`React with ${emoji}`}
                    className="justify-center px-2 py-1.5 text-lg"
                  >
                    {emoji}
                  </ContextMenuItem>
                ))}
              </ContextMenuSubContent>
            </ContextMenuSub>
          )}
          {!selectionMode && onEnterSelectionMode && (
            <ContextMenuItem onSelect={() => onEnterSelectionMode(message.Id)}>
              <CheckSquare className="size-4" aria-hidden="true" />
              Select Messages
            </ContextMenuItem>
          )}
          {isOwn && (
            <ContextMenuItem onSelect={startEdit}>
              <Pencil className="size-4" aria-hidden="true" />
              Edit Message
            </ContextMenuItem>
          )}
          {message.Content && (
            <ContextMenuItem onSelect={handleCopyText}>
              <Copy className="size-4" aria-hidden="true" />
              {t('messages.copyText')}
            </ContextMenuItem>
          )}
          {(onPin || onUnpin) && (
            <ContextMenuItem onSelect={handleTogglePin}>
              {message.PinnedAt ? <PinOff className="size-4" aria-hidden="true" /> : <Pin className="size-4" aria-hidden="true" />}
              {message.PinnedAt ? t('messages.unpin') : t('messages.pin')}
            </ContextMenuItem>
          )}
          {onForward && (
            <ContextMenuItem onSelect={() => setForwardOpen(true)}>
              <Forward className="size-4" aria-hidden="true" />
              {t('messages.forward')}
            </ContextMenuItem>
          )}
          {!isOwn && (
            <ContextMenuItem onSelect={() => setReportOpen(true)}>
              <Flag className="size-4" aria-hidden="true" />
              {t('reports.reportMessage')}
            </ContextMenuItem>
          )}
          <ContextMenuItem danger={isOwn} onSelect={handleDeleteAction}>
            {isOwn ? <Trash2 className="size-4" aria-hidden="true" /> : <EyeOff className="size-4" aria-hidden="true" />}
            {isOwn ? 'Delete Message' : 'Hide for me'}
          </ContextMenuItem>
        </ContextMenuContent>
      </ContextMenu>

      {isOwn && (
        <Modal
          open={confirmDeleteOpen}
          onOpenChange={setConfirmDeleteOpen}
          title="Delete message?"
          description="This deletes it for everyone in the channel. This can't be undone."
          footer={
            <>
              <Button variant="ghost" onClick={() => setConfirmDeleteOpen(false)}>
                Cancel
              </Button>
              <Button variant="danger" onClick={confirmDelete}>
                Delete Message
              </Button>
            </>
          }
        />
      )}

      {onForward && (
        <ForwardMessageModal
          open={forwardOpen}
          onOpenChange={setForwardOpen}
          sourceServerId={sourceServerId}
          sourceChannelId={sourceChannelId}
          sourceConversationId={sourceConversationId}
          onPick={handleForwardPick}
        />
      )}

      {!isOwn && (
        <Modal
          open={confirmHideOpen}
          onOpenChange={setConfirmHideOpen}
          title="Hide this message?"
          description="It'll disappear from your view only - everyone else can still see it. There's no way to unhide it yourself afterward."
          footer={
            <>
              <Button variant="ghost" onClick={() => setConfirmHideOpen(false)}>
                Cancel
              </Button>
              <Button variant="danger" onClick={confirmHide}>
                Hide Message
              </Button>
            </>
          }
        />
      )}

      {!isOwn && (
        <ReportModal
          open={reportOpen}
          onOpenChange={setReportOpen}
          targetType="Message"
          targetId={message.Id}
          title={t('reports.reportMessageTitle')}
          description={t('reports.reportMessageDescription')}
        />
      )}
    </>
  )
}
