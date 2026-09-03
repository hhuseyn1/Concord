using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Extensions;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Services;

public class GlobalSearchService(ApplicationDbContext context, FriendsService friendsService)
{
    private readonly ApplicationDbContext _context = context;
    private readonly FriendsService _friendsService = friendsService;

    public async Task<PagedResult<GlobalSearchResultResponse>> SearchAsync(Guid currentUserId, string query, int page, int pageSize)
    {
        if (string.IsNullOrWhiteSpace(query))
            throw new ParameterValidationException(nameof(query));

        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        var fetchLimit = page * pageSize;

        var myChannelIds = await _context.ServerMembers
            .Where(member => member.UserId == currentUserId)
            .Join(_context.Channels, member => member.ServerId, channel => channel.ServerId, (member, channel) => channel.Id)
            .ToListAsync();

        var myConversationIds = await _context.Conversations
            .Where(conversation => conversation.UserAId == currentUserId || conversation.UserBId == currentUserId)
            .Select(conversation => conversation.Id)
            .ToListAsync();

        var channelMatches = await _context.Messages
            .Where(message => myChannelIds.Contains(message.ChannelId))
            .Where(message => message.Content != null && EF.Functions.ILike(message.Content, $"%{query}%"))
            .Where(message => !_context.MessageHiddenForUsers.Any(hidden => hidden.MessageId == message.Id && hidden.UserId == currentUserId))
            .OrderByDescending(message => message.Created)
            .Take(fetchLimit)
            .ToListAsync();

        var conversationMatches = await _context.DirectMessages
            .Where(message => myConversationIds.Contains(message.ConversationId))
            .Where(message => message.Content != null && EF.Functions.ILike(message.Content, $"%{query}%"))
            .Where(message => !_context.DirectMessageHiddenForUsers.Any(hidden => hidden.DirectMessageId == message.Id && hidden.UserId == currentUserId))
            .OrderByDescending(message => message.Created)
            .Take(fetchLimit)
            .ToListAsync();

        var channelById = (await _context.Channels
            .Where(channel => channelMatches.Select(m => m.ChannelId).Contains(channel.Id))
            .ToListAsync())
            .ToDictionary(channel => channel.Id);

        var senderIds = channelMatches.Select(m => m.SenderId).Concat(conversationMatches.Select(m => m.SenderId)).Distinct().ToList();
        var usersById = await _context.Users
            .Where(user => senderIds.Contains(user.Id))
            .ToDictionaryAsync(user => user.Id);

        var blockedSenderIds = await _friendsService.GetBlockedUserIdsAsync(currentUserId, senderIds);

        var merged = channelMatches
            .Where(message => !blockedSenderIds.Contains(message.SenderId) && usersById.ContainsKey(message.SenderId) && channelById.ContainsKey(message.ChannelId))
            .Select(message => new GlobalSearchResultResponse
            {
                MessageId = message.Id,
                SourceType = MessageSourceType.Channel,
                ServerId = channelById[message.ChannelId].ServerId,
                ChannelId = message.ChannelId,
                Sender = usersById[message.SenderId].MapToPublicModel(),
                Content = message.Content,
                Created = message.Created
            })
            .Concat(conversationMatches
                .Where(message => !blockedSenderIds.Contains(message.SenderId) && usersById.ContainsKey(message.SenderId))
                .Select(message => new GlobalSearchResultResponse
                {
                    MessageId = message.Id,
                    SourceType = MessageSourceType.DirectMessage,
                    ConversationId = message.ConversationId,
                    Sender = usersById[message.SenderId].MapToPublicModel(),
                    Content = message.Content,
                    Created = message.Created
                }))
            .OrderByDescending(result => result.Created)
            .ToList();

        var totalCount =
            await _context.Messages.CountAsync(message =>
                myChannelIds.Contains(message.ChannelId) &&
                message.Content != null && EF.Functions.ILike(message.Content, $"%{query}%") &&
                !_context.MessageHiddenForUsers.Any(hidden => hidden.MessageId == message.Id && hidden.UserId == currentUserId)) +
            await _context.DirectMessages.CountAsync(message =>
                myConversationIds.Contains(message.ConversationId) &&
                message.Content != null && EF.Functions.ILike(message.Content, $"%{query}%") &&
                !_context.DirectMessageHiddenForUsers.Any(hidden => hidden.DirectMessageId == message.Id && hidden.UserId == currentUserId));

        var items = merged
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return new PagedResult<GlobalSearchResultResponse>
        {
            Items = items,
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }
}
