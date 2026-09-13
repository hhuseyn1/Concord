using System.Text.RegularExpressions;
using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Application.Realtime;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Extensions;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Services;

public class DirectMessagesService(
    ApplicationDbContext context,
    FriendsService friendsService,
    FilesService filesService,
    NotificationsService notificationsService,
    IDirectMessagesRealtimeNotifier realtimeNotifier,
    INotificationsRealtimeNotifier notificationsRealtimeNotifier)
{
    private const int MaxContentLength = 4000;
    private const int MaxEmojiLength = 32;

    private readonly ApplicationDbContext _context = context;
    private readonly FriendsService _friendsService = friendsService;
    private readonly FilesService _filesService = filesService;
    private readonly NotificationsService _notificationsService = notificationsService;
    private readonly IDirectMessagesRealtimeNotifier _realtimeNotifier = realtimeNotifier;
    private readonly INotificationsRealtimeNotifier _notificationsRealtimeNotifier = notificationsRealtimeNotifier;

    private static readonly Regex MentionTokenRegex = new(@"@([a-zA-Z0-9_]{1,32})", RegexOptions.Compiled);

    public async Task<Conversation> AssertConversationAccessAsync(Guid currentUserId, Guid conversationId)
    {
        var conversation = await _context.Conversations.FirstOrDefaultAsync(c => c.Id == conversationId);

        if (conversation is null || (conversation.UserAId != currentUserId && conversation.UserBId != currentUserId))
            throw new ConversationNotFoundException();

        return conversation;
    }

    public async Task<(Guid UserAId, Guid UserBId)> GetConversationParticipantsAsync(Guid conversationId)
    {
        var conversation = await _context.Conversations.FirstOrDefaultAsync(c => c.Id == conversationId);

        if (conversation is null)
            throw new ConversationNotFoundException();

        return (conversation.UserAId, conversation.UserBId);
    }

    public async Task<ConversationResponse> CreateOrGetConversationAsync(Guid currentUserId, Guid targetUserId)
    {
        if (targetUserId == currentUserId)
            throw new CannotTargetSelfException();

        var targetUser = await _context.Users.FirstOrDefaultAsync(user => user.Id == targetUserId);

        if (targetUser is null || targetUser.Disabled.HasValue)
            throw new UserNotFoundException(targetUserId);

        if (await _friendsService.AreBlockedAsync(currentUserId, targetUserId))
            throw new UserBlockedException();

        if (!await _friendsService.CanDirectMessageAsync(currentUserId, targetUser))
            throw new DirectMessagesNotAllowedException();

        var conversation = await GetOrCreateConversationEntityAsync(currentUserId, targetUserId);

        var presence = await _context.UserPresences.FirstOrDefaultAsync(p => p.UserId == targetUserId);
        var otherUserResponse = targetUser.MapToPublicModel(presence);

        var lastMessage = await GetLastVisibleMessageResponseAsync(currentUserId, conversation.Id);
        var unreadCount = await CountUnreadAsync(currentUserId, conversation);

        return conversation.MapToResponse(otherUserResponse, lastMessage, unreadCount);
    }

    public async Task<PagedResult<ConversationResponse>> GetConversationsAsync(Guid currentUserId, int page, int pageSize)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        var conversationsQuery = _context.Conversations
            .Where(c => c.UserAId == currentUserId || c.UserBId == currentUserId);

        var totalCount = await conversationsQuery.CountAsync();

        var conversations = await conversationsQuery
            .OrderByDescending(c => c.LastMessageAt ?? c.Created)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var otherUserIds = conversations
            .Select(c => c.UserAId == currentUserId ? c.UserBId : c.UserAId)
            .Distinct()
            .ToList();

        var usersById = await _context.Users
            .Where(user => otherUserIds.Contains(user.Id))
            .ToDictionaryAsync(user => user.Id);

        var presencesById = await _context.UserPresences
            .Where(presence => otherUserIds.Contains(presence.UserId))
            .ToDictionaryAsync(presence => presence.UserId);

        var blockedIds = await _friendsService.GetBlockedUserIdsAsync(currentUserId, otherUserIds);

        var items = new List<ConversationResponse>();

        foreach (var conversation in conversations)
        {
            var otherUserId = conversation.UserAId == currentUserId ? conversation.UserBId : conversation.UserAId;

            if (!usersById.TryGetValue(otherUserId, out var otherUser))
                continue;

            var otherUserPresence = blockedIds.Contains(otherUserId) ? null : presencesById.GetValueOrDefault(otherUserId);
            var lastMessage = await GetLastVisibleMessageResponseAsync(currentUserId, conversation.Id);
            var unreadCount = await CountUnreadAsync(currentUserId, conversation);

            items.Add(conversation.MapToResponse(otherUser.MapToPublicModel(otherUserPresence), lastMessage, unreadCount));
        }

        return new PagedResult<ConversationResponse>
        {
            Items = items,
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    public async Task<PagedResult<DirectMessageResponse>> GetMessagesAsync(Guid currentUserId, Guid conversationId, int page, int pageSize)
    {
        var conversation = await AssertConversationAccessAsync(currentUserId, conversationId);

        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        var messagesQuery = _context.DirectMessages
            .Where(message => message.ConversationId == conversationId)
            .Where(message => !_context.DirectMessageHiddenForUsers
                .Any(hidden => hidden.DirectMessageId == message.Id && hidden.UserId == currentUserId));

        var totalCount = await messagesQuery.CountAsync();

        var messages = await messagesQuery
            .OrderByDescending(message => message.Created)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Join(_context.Users,
                message => message.SenderId,
                user => user.Id,
                (message, user) => new { Message = message, Sender = user })
            .ToListAsync();

        var senderIds = messages.Select(x => x.Sender.Id).Distinct().ToList();

        var presencesById = await _context.UserPresences
            .Where(presence => senderIds.Contains(presence.UserId))
            .ToDictionaryAsync(presence => presence.UserId);

        var blockedSenderIds = await _friendsService.GetBlockedUserIdsAsync(currentUserId, senderIds);

        var reactionsByMessage = await GetReactionsByMessageIdsAsync(messages.Select(x => x.Message.Id).ToList());
        var mentionsByMessage = await GetMentionedUserIdsByMessageIdsAsync(messages.Select(x => x.Message.Id).ToList());

        if (page == 1)
        {
            if (conversation.UserAId == currentUserId) conversation.LastReadAtA = DateTime.UtcNow;
            else conversation.LastReadAtB = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            if (await IsReadReceiptsEnabledAsync(currentUserId))
            {
                var otherUserId = conversation.UserAId == currentUserId ? conversation.UserBId : conversation.UserAId;
                await _realtimeNotifier.ConversationReadAsync(conversationId, otherUserId, currentUserId, DateTime.UtcNow);
            }
        }

        return new PagedResult<DirectMessageResponse>
        {
            Items = messages
                .Select(x => x.Message.MapToResponse(
                    x.Sender,
                    blockedSenderIds.Contains(x.Sender.Id) ? null : presencesById.GetValueOrDefault(x.Sender.Id),
                    reactionsByMessage.GetValueOrDefault(x.Message.Id, []),
                    mentionsByMessage.GetValueOrDefault(x.Message.Id, [])))
                .ToList(),
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    public async Task<DirectMessageResponse> SendMessageAsync(Guid currentUserId, Guid conversationId, SendMessageRequest request)
    {
        var conversation = await AssertConversationAccessAsync(currentUserId, conversationId);

        var otherUserId = conversation.UserAId == currentUserId ? conversation.UserBId : conversation.UserAId;

        if (await _friendsService.AreBlockedAsync(currentUserId, otherUserId))
            throw new UserBlockedException();

        var hasAttachment = !string.IsNullOrWhiteSpace(request.AttachmentUrl);

        if (string.IsNullOrWhiteSpace(request.Content) && !hasAttachment)
            throw new ParameterValidationException(nameof(request.Content));

        if (!string.IsNullOrWhiteSpace(request.Content) && request.Content.Length > MaxContentLength)
            throw new ParameterValidationException(nameof(request.Content));

        if (hasAttachment && !await _filesService.IsOwnAttachmentAsync(currentUserId, request.AttachmentUrl))
            throw new ParameterValidationException(nameof(request.AttachmentUrl));

        if (request.ReplyToMessageId is Guid replyToId &&
            !await _context.DirectMessages.AnyAsync(message => message.Id == replyToId && message.ConversationId == conversationId))
            throw new MessageNotFoundException();

        var sender = await _context.Users.FirstOrDefaultAsync(user => user.Id == currentUserId);

        if (sender is null)
            throw new UserNotFoundException(currentUserId);

        var senderPresence = await _context.UserPresences.FirstOrDefaultAsync(presence => presence.UserId == currentUserId);

        var message = new DirectMessage
        {
            ConversationId = conversationId,
            SenderId = currentUserId,
            Content = request.Content ?? string.Empty,
            AttachmentUrl = request.AttachmentUrl,
            ReplyToMessageId = request.ReplyToMessageId
        };

        _context.DirectMessages.Add(message);
        conversation.LastMessageAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        var mentionedUserIds = await ResolveAndStoreMentionsAsync(conversation, message, request.Content);

        var result = message.MapToResponse(sender, senderPresence, mentionedUserIds: mentionedUserIds);

        await _realtimeNotifier.MessageReceivedAsync(conversation.UserAId, conversation.UserBId, result);

        foreach (var mentionedUserId in mentionedUserIds)
        {
            await _notificationsRealtimeNotifier.NotifyAsync(
                mentionedUserId,
                NotificationType.Mention,
                currentUserId,
                contextConversationId: conversationId,
                contextMessageId: result.Id,
                reason: null);
        }

        // A DM is inherently "for" the other person - unlike a channel, there's no one else it could
        // be meant for, so (unlike channel messages) it shouldn't need an explicit @mention to notify
        // them. Skipped when they were already @mentioned above: ResolveAndStoreMentionsAsync in a
        // DM can only ever resolve to this same otherUserId, so that path already persisted and
        // pushed a notification for this exact message - a second one here would just be a duplicate.
        if (!mentionedUserIds.Contains(otherUserId))
        {
            await _notificationsService.NotifyDirectMessageReceivedAsync(otherUserId, currentUserId, conversationId, result.Id, result.Content);
            await _notificationsRealtimeNotifier.NotifyAsync(
                otherUserId,
                NotificationType.DirectMessageReceived,
                currentUserId,
                contextConversationId: conversationId,
                contextMessageId: result.Id,
                reason: null);
            await _context.SaveChangesAsync();
        }

        return result;
    }

    private async Task<List<Guid>> ResolveAndStoreMentionsAsync(Conversation conversation, DirectMessage message, string? content)
    {
        var usernames = ExtractMentionedUsernames(content);
        if (usernames.Count == 0)
            return [];

        var otherUserId = conversation.UserAId == message.SenderId ? conversation.UserBId : conversation.UserAId;

        var otherUsername = await _context.Users
            .Where(user => user.Id == otherUserId)
            .Select(user => user.Username)
            .FirstOrDefaultAsync();

        if (otherUsername is null || !usernames.Contains(otherUsername.ToLower()))
            return [];

        _context.DirectMessageMentions.Add(new DirectMessageMention
        {
            DirectMessageId = message.Id,
            MentionedUserId = otherUserId
        });

        await _notificationsService.NotifyMentionAsync(otherUserId, message.SenderId, null, null, conversation.Id, message.Id, content);

        await _context.SaveChangesAsync();

        return [otherUserId];
    }

    private static HashSet<string> ExtractMentionedUsernames(string? content)
    {
        if (string.IsNullOrEmpty(content))
            return [];

        return MentionTokenRegex.Matches(content)
            .Select(match => match.Groups[1].Value.ToLower())
            .ToHashSet();
    }

    public async Task<DirectMessageResponse> EditMessageAsync(Guid currentUserId, Guid conversationId, Guid messageId, EditMessageRequest request)
    {
        var conversation = await AssertConversationAccessAsync(currentUserId, conversationId);

        var message = await GetMessageInConversationAsync(conversationId, messageId);

        if (message.SenderId != currentUserId)
            throw new NotMessageAuthorException();

        if (string.IsNullOrWhiteSpace(request.Content))
            throw new ParameterValidationException(nameof(request.Content));

        if (request.Content.Length > MaxContentLength)
            throw new ParameterValidationException(nameof(request.Content));

        message.Content = request.Content;
        message.EditedAtUtc = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        var sender = await _context.Users.FirstOrDefaultAsync(user => user.Id == currentUserId);

        if (sender is null)
            throw new UserNotFoundException(currentUserId);

        var senderPresence = await _context.UserPresences.FirstOrDefaultAsync(presence => presence.UserId == currentUserId);
        var reactionsByMessage = await GetReactionsByMessageIdsAsync([messageId]);
        var mentionsByMessage = await GetMentionedUserIdsByMessageIdsAsync([messageId]);

        var result = message.MapToResponse(sender, senderPresence, reactionsByMessage.GetValueOrDefault(messageId, []), mentionsByMessage.GetValueOrDefault(messageId, []));

        await _realtimeNotifier.MessageEditedAsync(conversation.UserAId, conversation.UserBId, result);

        return result;
    }

    public async Task<DirectMessageResponse> ToggleReactionAsync(Guid currentUserId, Guid conversationId, Guid messageId, ReactionRequest request)
    {
        var conversation = await AssertConversationAccessAsync(currentUserId, conversationId);

        var message = await GetMessageInConversationAsync(conversationId, messageId);

        if (string.IsNullOrWhiteSpace(request.Emoji) || request.Emoji.Length > MaxEmojiLength)
            throw new ParameterValidationException(nameof(request.Emoji));

        var existing = await _context.DirectMessageReactions.FirstOrDefaultAsync(reaction =>
            reaction.DirectMessageId == messageId && reaction.UserId == currentUserId && reaction.Emoji == request.Emoji);

        if (existing is not null)
        {
            _context.DirectMessageReactions.Remove(existing);
        }
        else
        {
            _context.DirectMessageReactions.Add(new DirectMessageReaction
            {
                DirectMessageId = messageId,
                UserId = currentUserId,
                Emoji = request.Emoji
            });
        }

        await _context.SaveChangesAsync();

        var sender = await _context.Users.FirstOrDefaultAsync(user => user.Id == message.SenderId);

        if (sender is null)
            throw new UserNotFoundException(message.SenderId);

        var senderPresence = await _context.UserPresences.FirstOrDefaultAsync(presence => presence.UserId == message.SenderId);
        var reactionsByMessage = await GetReactionsByMessageIdsAsync([messageId]);
        var mentionsByMessage = await GetMentionedUserIdsByMessageIdsAsync([messageId]);

        var result = message.MapToResponse(sender, senderPresence, reactionsByMessage.GetValueOrDefault(messageId, []), mentionsByMessage.GetValueOrDefault(messageId, []));

        await _realtimeNotifier.MessageReactionsChangedAsync(conversation.UserAId, conversation.UserBId, result);

        return result;
    }

    private async Task<Dictionary<Guid, List<Guid>>> GetMentionedUserIdsByMessageIdsAsync(List<Guid> messageIds)
    {
        var mentions = await _context.DirectMessageMentions
            .Where(mention => messageIds.Contains(mention.DirectMessageId))
            .ToListAsync();

        return mentions
            .GroupBy(mention => mention.DirectMessageId)
            .ToDictionary(group => group.Key, group => group.Select(mention => mention.MentionedUserId).ToList());
    }

    private async Task<Dictionary<Guid, List<ReactionSummaryResponse>>> GetReactionsByMessageIdsAsync(List<Guid> messageIds)
    {
        var reactions = await _context.DirectMessageReactions
            .Where(reaction => messageIds.Contains(reaction.DirectMessageId))
            .ToListAsync();

        return reactions
            .GroupBy(reaction => reaction.DirectMessageId)
            .ToDictionary(
                messageGroup => messageGroup.Key,
                messageGroup => messageGroup
                    .GroupBy(reaction => reaction.Emoji)
                    .Select(emojiGroup => new ReactionSummaryResponse
                    {
                        Emoji = emojiGroup.Key,
                        UserIds = emojiGroup.Select(reaction => reaction.UserId).ToList()
                    })
                    .ToList());
    }

    public async Task<bool> DeleteMessageAsync(Guid currentUserId, Guid conversationId, Guid messageId)
    {
        var conversation = await AssertConversationAccessAsync(currentUserId, conversationId);

        var message = await GetMessageInConversationAsync(conversationId, messageId);

        if (message.SenderId == currentUserId)
        {
            var attachmentUrl = message.AttachmentUrl;

            _context.DirectMessages.Remove(message);
            await _context.SaveChangesAsync();

            if (!string.IsNullOrWhiteSpace(attachmentUrl))
                await _filesService.DeleteFileAsync(attachmentUrl);

            await _realtimeNotifier.MessageDeletedAsync(conversation.UserAId, conversation.UserBId, conversationId, messageId);

            return true;
        }

        var alreadyHidden = await _context.DirectMessageHiddenForUsers
            .AnyAsync(hidden => hidden.DirectMessageId == messageId && hidden.UserId == currentUserId);

        if (!alreadyHidden)
        {
            _context.DirectMessageHiddenForUsers.Add(new DirectMessageHiddenForUser
            {
                DirectMessageId = messageId,
                UserId = currentUserId
            });

            await _context.SaveChangesAsync();
        }

        return false;
    }

    private async Task<Conversation> GetOrCreateConversationEntityAsync(Guid userA, Guid userB)
    {
        var (first, second) = userA.CompareTo(userB) <= 0 ? (userA, userB) : (userB, userA);

        var conversation = await _context.Conversations
            .FirstOrDefaultAsync(c => c.UserAId == first && c.UserBId == second);

        if (conversation is not null)
            return conversation;

        conversation = new Conversation { UserAId = first, UserBId = second };
        _context.Conversations.Add(conversation);
        await _context.SaveChangesAsync();

        return conversation;
    }

    private async Task<DirectMessageResponse?> GetLastVisibleMessageResponseAsync(Guid currentUserId, Guid conversationId)
    {
        var lastMessage = await _context.DirectMessages
            .Where(message => message.ConversationId == conversationId)
            .Where(message => !_context.DirectMessageHiddenForUsers
                .Any(hidden => hidden.DirectMessageId == message.Id && hidden.UserId == currentUserId))
            .OrderByDescending(message => message.Created)
            .FirstOrDefaultAsync();

        if (lastMessage is null)
            return null;

        var sender = await _context.Users.FirstOrDefaultAsync(user => user.Id == lastMessage.SenderId);

        if (sender is null)
            return null;

        var blocked = await _friendsService.AreBlockedAsync(currentUserId, lastMessage.SenderId);
        var presence = blocked ? null : await _context.UserPresences.FirstOrDefaultAsync(p => p.UserId == lastMessage.SenderId);

        return lastMessage.MapToResponse(sender, presence);
    }

    private async Task<int> CountUnreadAsync(Guid currentUserId, Conversation conversation)
    {
        var myLastReadAt = conversation.UserAId == currentUserId ? conversation.LastReadAtA : conversation.LastReadAtB;

        return await _context.DirectMessages.CountAsync(message =>
            message.ConversationId == conversation.Id &&
            message.SenderId != currentUserId &&
            (myLastReadAt == null || message.Created > myLastReadAt) &&
            !_context.DirectMessageHiddenForUsers.Any(hidden => hidden.DirectMessageId == message.Id && hidden.UserId == currentUserId));
    }

    private async Task<DirectMessage> GetMessageInConversationAsync(Guid conversationId, Guid messageId)
    {
        var message = await _context.DirectMessages.FirstOrDefaultAsync(message => message.Id == messageId);

        if (message is null || message.ConversationId != conversationId)
            throw new MessageNotFoundException();

        return message;
    }

    public async Task<bool> IsReadReceiptsEnabledAsync(Guid userId)
    {
        return await _context.Users
            .Where(user => user.Id == userId)
            .Select(user => user.ReadReceiptsEnabled)
            .FirstOrDefaultAsync();
    }

    public async Task<PagedResult<DirectMessageResponse>> SearchMessagesAsync(Guid currentUserId, Guid conversationId, string query, int page, int pageSize)
    {
        await AssertConversationAccessAsync(currentUserId, conversationId);

        if (string.IsNullOrWhiteSpace(query))
            throw new ParameterValidationException(nameof(query));

        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        var messagesQuery = _context.DirectMessages
            .Where(message => message.ConversationId == conversationId)
            .Where(message => message.Content != null && EF.Functions.ILike(message.Content, $"%{query}%"))
            .Where(message => !_context.DirectMessageHiddenForUsers
                .Any(hidden => hidden.DirectMessageId == message.Id && hidden.UserId == currentUserId));

        var totalCount = await messagesQuery.CountAsync();

        var messages = await messagesQuery
            .OrderByDescending(message => message.Created)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Join(_context.Users,
                message => message.SenderId,
                user => user.Id,
                (message, user) => new { Message = message, Sender = user })
            .ToListAsync();

        var senderIds = messages.Select(x => x.Sender.Id).Distinct().ToList();
        var blockedSenderIds = await _friendsService.GetBlockedUserIdsAsync(currentUserId, senderIds);
        var presencesById = await _context.UserPresences
            .Where(presence => senderIds.Contains(presence.UserId))
            .ToDictionaryAsync(presence => presence.UserId);
        var reactionsByMessage = await GetReactionsByMessageIdsAsync(messages.Select(x => x.Message.Id).ToList());

        return new PagedResult<DirectMessageResponse>
        {
            Items = messages
                .Select(x => x.Message.MapToResponse(
                    x.Sender,
                    blockedSenderIds.Contains(x.Sender.Id) ? null : presencesById.GetValueOrDefault(x.Sender.Id),
                    reactionsByMessage.GetValueOrDefault(x.Message.Id, [])))
                .ToList(),
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    public async Task<DirectMessageResponse> PinMessageAsync(Guid currentUserId, Guid conversationId, Guid messageId)
    {
        var conversation = await AssertConversationAccessAsync(currentUserId, conversationId);
        var message = await GetMessageInConversationAsync(conversationId, messageId);

        message.PinnedAt = DateTime.UtcNow;
        message.PinnedByUserId = currentUserId;

        await _context.SaveChangesAsync();

        var result = await BuildMessageResponseAsync(message);

        await _realtimeNotifier.MessagePinnedAsync(conversation.UserAId, conversation.UserBId, result);

        return result;
    }

    public async Task<DirectMessageResponse> UnpinMessageAsync(Guid currentUserId, Guid conversationId, Guid messageId)
    {
        var conversation = await AssertConversationAccessAsync(currentUserId, conversationId);
        var message = await GetMessageInConversationAsync(conversationId, messageId);

        message.PinnedAt = null;
        message.PinnedByUserId = null;

        await _context.SaveChangesAsync();

        var result = await BuildMessageResponseAsync(message);

        await _realtimeNotifier.MessageUnpinnedAsync(conversation.UserAId, conversation.UserBId, result);

        return result;
    }

    public async Task<List<DirectMessageResponse>> GetPinnedMessagesAsync(Guid currentUserId, Guid conversationId)
    {
        await AssertConversationAccessAsync(currentUserId, conversationId);

        var messages = await _context.DirectMessages
            .Where(message => message.ConversationId == conversationId && message.PinnedAt != null)
            .OrderByDescending(message => message.PinnedAt)
            .Join(_context.Users,
                message => message.SenderId,
                user => user.Id,
                (message, user) => new { Message = message, Sender = user })
            .ToListAsync();

        var reactionsByMessage = await GetReactionsByMessageIdsAsync(messages.Select(x => x.Message.Id).ToList());
        var mentionsByMessage = await GetMentionedUserIdsByMessageIdsAsync(messages.Select(x => x.Message.Id).ToList());

        return messages
            .Select(x => x.Message.MapToResponse(
                x.Sender,
                null,
                reactionsByMessage.GetValueOrDefault(x.Message.Id, []),
                mentionsByMessage.GetValueOrDefault(x.Message.Id, [])))
            .ToList();
    }

    public async Task<(string? Content, string? AttachmentUrl, Guid SenderId, DateTime CreatedAt)> GetForwardableContentAsync(Guid currentUserId, Guid conversationId, Guid messageId)
    {
        await AssertConversationAccessAsync(currentUserId, conversationId);
        var message = await GetMessageInConversationAsync(conversationId, messageId);

        return (message.Content, message.AttachmentUrl, message.SenderId, message.Created);
    }

    public async Task<DirectMessageResponse> ReceiveForwardedMessageAsync(
        Guid currentUserId, Guid conversationId, string? content, string? attachmentUrl, Guid forwardedFromSenderId, DateTime forwardedFromCreatedAt)
    {
        var conversation = await AssertConversationAccessAsync(currentUserId, conversationId);

        var otherUserId = conversation.UserAId == currentUserId ? conversation.UserBId : conversation.UserAId;
        if (await _friendsService.AreBlockedAsync(currentUserId, otherUserId))
            throw new UserBlockedException();

        var sender = await _context.Users.FirstOrDefaultAsync(user => user.Id == currentUserId)
                     ?? throw new UserNotFoundException(currentUserId);

        var message = new DirectMessage
        {
            ConversationId = conversationId,
            SenderId = currentUserId,
            Content = content ?? string.Empty,
            AttachmentUrl = attachmentUrl,
            ForwardedFromSenderId = forwardedFromSenderId,
            ForwardedFromCreatedAt = forwardedFromCreatedAt
        };

        _context.DirectMessages.Add(message);
        conversation.LastMessageAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        var senderPresence = await _context.UserPresences.FirstOrDefaultAsync(presence => presence.UserId == currentUserId);

        return message.MapToResponse(sender, senderPresence);
    }

    private async Task<DirectMessageResponse> BuildMessageResponseAsync(DirectMessage message)
    {
        var sender = await _context.Users.FirstOrDefaultAsync(user => user.Id == message.SenderId)
                     ?? throw new UserNotFoundException(message.SenderId);

        var senderPresence = await _context.UserPresences.FirstOrDefaultAsync(presence => presence.UserId == message.SenderId);
        var reactionsByMessage = await GetReactionsByMessageIdsAsync([message.Id]);
        var mentionsByMessage = await GetMentionedUserIdsByMessageIdsAsync([message.Id]);

        return message.MapToResponse(sender, senderPresence, reactionsByMessage.GetValueOrDefault(message.Id, []), mentionsByMessage.GetValueOrDefault(message.Id, []));
    }
}
