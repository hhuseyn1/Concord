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

public class MessagesService(
    ApplicationDbContext context,
    ChannelsService channelsService,
    FilesService filesService,
    FriendsService friendsService,
    ServersService serversService,
    PermissionService permissionService,
    NotificationsService notificationsService,
    IMessagesRealtimeNotifier realtimeNotifier,
    INotificationsRealtimeNotifier notificationsRealtimeNotifier)
{
    private const int MaxContentLength = 4000;
    private const int MaxEmojiLength = 32;

    private readonly ApplicationDbContext _context = context;
    private readonly ChannelsService _channelsService = channelsService;
    private readonly FilesService _filesService = filesService;
    private readonly FriendsService _friendsService = friendsService;
    private readonly ServersService _serversService = serversService;
    private readonly PermissionService _permissionService = permissionService;
    private readonly NotificationsService _notificationsService = notificationsService;
    private readonly IMessagesRealtimeNotifier _realtimeNotifier = realtimeNotifier;
    private readonly INotificationsRealtimeNotifier _notificationsRealtimeNotifier = notificationsRealtimeNotifier;

    private static readonly Regex MentionTokenRegex = new(@"@([a-zA-Z0-9_]{1,32})", RegexOptions.Compiled);

    public async Task<MessageResponse> SendMessageAsync(Guid currentUserId, Guid serverId, Guid channelId, SendMessageRequest request)
    {
        await _channelsService.AssertChannelPermissionAsync(currentUserId, channelId, ServerPermission.SendMessages);

        var hasAttachment = !string.IsNullOrWhiteSpace(request.AttachmentUrl);

        if (string.IsNullOrWhiteSpace(request.Content) && !hasAttachment)
            throw new ParameterValidationException(nameof(request.Content));

        if (!string.IsNullOrWhiteSpace(request.Content) && request.Content.Length > MaxContentLength)
            throw new ParameterValidationException(nameof(request.Content));

        if (hasAttachment && !await _filesService.IsOwnAttachmentAsync(currentUserId, request.AttachmentUrl))
            throw new ParameterValidationException(nameof(request.AttachmentUrl));

        if (request.ReplyToMessageId is Guid replyToId &&
            !await _context.Messages.AnyAsync(message => message.Id == replyToId && message.ChannelId == channelId))
            throw new MessageNotFoundException();

        var sender = await _context.Users.FirstOrDefaultAsync(user => user.Id == currentUserId);

        if (sender is null)
            throw new UserNotFoundException(currentUserId);

        var senderPresence = await _context.UserPresences.FirstOrDefaultAsync(presence => presence.UserId == currentUserId);

        var message = new Message
        {
            ChannelId = channelId,
            SenderId = currentUserId,
            Content = request.Content ?? string.Empty,
            AttachmentUrl = request.AttachmentUrl,
            ReplyToMessageId = request.ReplyToMessageId
        };

        _context.Messages.Add(message);

        await _context.SaveChangesAsync();

        var (mentionedUserIds, everyoneRecipientIds) = await ResolveAndStoreMentionsAsync(channelId, message, request.Content);

        var result = message.MapToResponse(sender, senderPresence, mentionedUserIds: mentionedUserIds);

        await _realtimeNotifier.MessageReceivedAsync(channelId, result);

        foreach (var mentionedUserId in mentionedUserIds.Concat(everyoneRecipientIds))
        {
            await _notificationsRealtimeNotifier.NotifyAsync(
                mentionedUserId,
                NotificationType.Mention,
                currentUserId,
                contextServerId: serverId,
                contextChannelId: channelId,
                contextMessageId: result.Id,
                reason: null);
        }

        return result;
    }

    private async Task<(List<Guid> MentionedUserIds, List<Guid> EveryoneRecipientIds)> ResolveAndStoreMentionsAsync(Guid channelId, Message message, string? content)
    {
        var usernames = ExtractMentionedUsernames(content);

        var channel = await _context.Channels.FirstOrDefaultAsync(c => c.Id == channelId);
        if (channel is null)
            return ([], []);

        var triggersEveryone = usernames.Remove("everyone")
            && (await _permissionService.ResolveAsync(message.SenderId, channel.ServerId)).Has(ServerPermission.MentionEveryone);

        var mentionedUserIds = new List<Guid>();

        if (usernames.Count > 0)
        {
            mentionedUserIds = await _context.ServerMembers
                .Where(member => member.ServerId == channel.ServerId && member.UserId != message.SenderId)
                .Join(_context.Users,
                    member => member.UserId,
                    user => user.Id,
                    (member, user) => user)
                .Where(user => user.Username != null && usernames.Contains(user.Username.ToLower()))
                .Select(user => user.Id)
                .Distinct()
                .ToListAsync();

            if (mentionedUserIds.Count > 0)
            {
                _context.MessageMentions.AddRange(mentionedUserIds.Select(userId => new MessageMention
                {
                    MessageId = message.Id,
                    MentionedUserId = userId
                }));

                foreach (var mentionedUserId in mentionedUserIds)
                    await _notificationsService.NotifyMentionAsync(mentionedUserId, message.SenderId, channel.ServerId, channelId, null, message.Id, content);
            }
        }

        var everyoneRecipientIds = new List<Guid>();

        if (triggersEveryone)
        {
            message.MentionsEveryone = true;

            everyoneRecipientIds = await _context.ServerMembers
                .Where(member => member.ServerId == channel.ServerId && member.UserId != message.SenderId)
                .Select(member => member.UserId)
                .Where(userId => !mentionedUserIds.Contains(userId))
                .ToListAsync();

            if (everyoneRecipientIds.Count > 0)
                await _notificationsService.NotifyMentionsBulkAsync(everyoneRecipientIds, message.SenderId, channel.ServerId, channelId, message.Id);
        }

        if (mentionedUserIds.Count > 0 || triggersEveryone)
            await _context.SaveChangesAsync();

        return (mentionedUserIds, everyoneRecipientIds);
    }

    private static HashSet<string> ExtractMentionedUsernames(string? content)
    {
        if (string.IsNullOrEmpty(content))
            return [];

        return MentionTokenRegex.Matches(content)
            .Select(match => match.Groups[1].Value.ToLower())
            .ToHashSet();
    }

    public async Task<MessageResponse> EditMessageAsync(Guid currentUserId, Guid channelId, Guid messageId, EditMessageRequest request)
    {
        await _channelsService.AssertChannelMemberAsync(currentUserId, channelId);

        var message = await GetMessageInChannelAsync(channelId, messageId);

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

        await _realtimeNotifier.MessageEditedAsync(channelId, result);

        return result;
    }

    public async Task<bool> DeleteMessageAsync(Guid currentUserId, Guid channelId, Guid messageId)
    {
        var channel = await _channelsService.AssertChannelMemberAsync(currentUserId, channelId);

        var message = await GetMessageInChannelAsync(channelId, messageId);

        var canDeleteForEveryone = message.SenderId == currentUserId
            || (await _permissionService.ResolveAsync(currentUserId, channel.ServerId)).Has(ServerPermission.ManageMessages);

        if (canDeleteForEveryone)
        {
            var attachmentUrl = message.AttachmentUrl;

            _context.Messages.Remove(message);
            await _context.SaveChangesAsync();

            if (!string.IsNullOrWhiteSpace(attachmentUrl))
                await _filesService.DeleteFileAsync(attachmentUrl);

            await _realtimeNotifier.MessageDeletedAsync(channelId, messageId);

            return true;
        }

        var alreadyHidden = await _context.MessageHiddenForUsers
            .AnyAsync(hidden => hidden.MessageId == messageId && hidden.UserId == currentUserId);

        if (!alreadyHidden)
        {
            _context.MessageHiddenForUsers.Add(new MessageHiddenForUser
            {
                MessageId = messageId,
                UserId = currentUserId
            });

            await _context.SaveChangesAsync();
        }

        return false;
    }

    public async Task<PagedResult<MessageResponse>> GetMessagesAsync(Guid currentUserId, Guid channelId, int page, int pageSize)
    {
        await _channelsService.AssertChannelMemberAsync(currentUserId, channelId);

        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        var messagesQuery = _context.Messages
            .Where(message => message.ChannelId == channelId)
            .Where(message => !_context.MessageHiddenForUsers
                .Any(hidden => hidden.MessageId == message.Id && hidden.UserId == currentUserId));

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
            var readState = await _context.ChannelReadStates
                .FirstOrDefaultAsync(state => state.ChannelId == channelId && state.UserId == currentUserId);

            if (readState is null)
            {
                _context.ChannelReadStates.Add(new ChannelReadState
                {
                    ChannelId = channelId,
                    UserId = currentUserId,
                    LastReadAtUtc = DateTime.UtcNow
                });
            }
            else
            {
                readState.LastReadAtUtc = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
        }

        return new PagedResult<MessageResponse>
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

    public async Task<MessageResponse> ToggleReactionAsync(Guid currentUserId, Guid channelId, Guid messageId, ReactionRequest request)
    {
        await _channelsService.AssertChannelMemberAsync(currentUserId, channelId);

        var message = await GetMessageInChannelAsync(channelId, messageId);

        if (string.IsNullOrWhiteSpace(request.Emoji) || request.Emoji.Length > MaxEmojiLength)
            throw new ParameterValidationException(nameof(request.Emoji));

        var existing = await _context.MessageReactions.FirstOrDefaultAsync(reaction =>
            reaction.MessageId == messageId && reaction.UserId == currentUserId && reaction.Emoji == request.Emoji);

        if (existing is not null)
        {
            _context.MessageReactions.Remove(existing);
        }
        else
        {
            _context.MessageReactions.Add(new MessageReaction
            {
                MessageId = messageId,
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

        await _realtimeNotifier.MessageReactionsChangedAsync(channelId, result);

        return result;
    }

    private async Task<Dictionary<Guid, List<Guid>>> GetMentionedUserIdsByMessageIdsAsync(List<Guid> messageIds)
    {
        var mentions = await _context.MessageMentions
            .Where(mention => messageIds.Contains(mention.MessageId))
            .ToListAsync();

        return mentions
            .GroupBy(mention => mention.MessageId)
            .ToDictionary(group => group.Key, group => group.Select(mention => mention.MentionedUserId).ToList());
    }

    private async Task<Dictionary<Guid, List<ReactionSummaryResponse>>> GetReactionsByMessageIdsAsync(List<Guid> messageIds)
    {
        var reactions = await _context.MessageReactions
            .Where(reaction => messageIds.Contains(reaction.MessageId))
            .ToListAsync();

        return reactions
            .GroupBy(reaction => reaction.MessageId)
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

    private async Task<Message> GetMessageInChannelAsync(Guid channelId, Guid messageId)
    {
        var message = await _context.Messages
            .FirstOrDefaultAsync(message => message.Id == messageId);

        if (message is null || message.ChannelId != channelId)
            throw new MessageNotFoundException();

        return message;
    }

    public async Task<MessageResponse> PinMessageAsync(Guid currentUserId, Guid channelId, Guid messageId)
    {
        var channel = await _channelsService.AssertChannelMemberAsync(currentUserId, channelId);
        var message = await GetMessageInChannelAsync(channelId, messageId);

        var canManage = (await _permissionService.ResolveAsync(currentUserId, channel.ServerId)).Has(ServerPermission.ManageMessages);

        if (!canManage && message.SenderId != currentUserId)
            throw new NotAllowedToPinException();

        message.PinnedAt = DateTime.UtcNow;
        message.PinnedByUserId = currentUserId;

        await _context.SaveChangesAsync();

        var result = await BuildMessageResponseAsync(message);

        await _realtimeNotifier.MessagePinnedAsync(channelId, result);

        return result;
    }

    public async Task<MessageResponse> UnpinMessageAsync(Guid currentUserId, Guid channelId, Guid messageId)
    {
        var channel = await _channelsService.AssertChannelMemberAsync(currentUserId, channelId);
        var message = await GetMessageInChannelAsync(channelId, messageId);

        var canManage = (await _permissionService.ResolveAsync(currentUserId, channel.ServerId)).Has(ServerPermission.ManageMessages);

        if (!canManage && message.SenderId != currentUserId && message.PinnedByUserId != currentUserId)
            throw new NotAllowedToPinException();

        message.PinnedAt = null;
        message.PinnedByUserId = null;

        await _context.SaveChangesAsync();

        var result = await BuildMessageResponseAsync(message);

        await _realtimeNotifier.MessageUnpinnedAsync(channelId, result);

        return result;
    }

    public async Task<List<MessageResponse>> GetPinnedMessagesAsync(Guid currentUserId, Guid channelId)
    {
        await _channelsService.AssertChannelMemberAsync(currentUserId, channelId);

        var messages = await _context.Messages
            .Where(message => message.ChannelId == channelId && message.PinnedAt != null)
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

    public async Task<(string? Content, string? AttachmentUrl, Guid SenderId, DateTime CreatedAt)> GetForwardableContentAsync(Guid currentUserId, Guid channelId, Guid messageId)
    {
        await _channelsService.AssertChannelMemberAsync(currentUserId, channelId);
        var message = await GetMessageInChannelAsync(channelId, messageId);

        return (message.Content, message.AttachmentUrl, message.SenderId, message.Created);
    }

    public async Task<MessageResponse> ReceiveForwardedMessageAsync(
        Guid currentUserId, Guid channelId, string? content, string? attachmentUrl, Guid forwardedFromSenderId, DateTime forwardedFromCreatedAt)
    {
        await _channelsService.AssertChannelPermissionAsync(currentUserId, channelId, ServerPermission.SendMessages);

        var sender = await _context.Users.FirstOrDefaultAsync(user => user.Id == currentUserId)
                     ?? throw new UserNotFoundException(currentUserId);

        var message = new Message
        {
            ChannelId = channelId,
            SenderId = currentUserId,
            Content = content ?? string.Empty,
            AttachmentUrl = attachmentUrl,
            ForwardedFromSenderId = forwardedFromSenderId,
            ForwardedFromCreatedAt = forwardedFromCreatedAt
        };

        _context.Messages.Add(message);
        await _context.SaveChangesAsync();

        var senderPresence = await _context.UserPresences.FirstOrDefaultAsync(presence => presence.UserId == currentUserId);

        return message.MapToResponse(sender, senderPresence);
    }

    private async Task<MessageResponse> BuildMessageResponseAsync(Message message)
    {
        var sender = await _context.Users.FirstOrDefaultAsync(user => user.Id == message.SenderId)
                     ?? throw new UserNotFoundException(message.SenderId);

        var senderPresence = await _context.UserPresences.FirstOrDefaultAsync(presence => presence.UserId == message.SenderId);
        var reactionsByMessage = await GetReactionsByMessageIdsAsync([message.Id]);
        var mentionsByMessage = await GetMentionedUserIdsByMessageIdsAsync([message.Id]);

        return message.MapToResponse(sender, senderPresence, reactionsByMessage.GetValueOrDefault(message.Id, []), mentionsByMessage.GetValueOrDefault(message.Id, []));
    }
}
