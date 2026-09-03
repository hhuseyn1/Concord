using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Extensions;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Services;

public class NotificationsService(ApplicationDbContext context)
{
    private readonly ApplicationDbContext _context = context;

    internal Task NotifyFriendRequestReceivedAsync(Guid recipientUserId, Guid requesterUserId)
    {
        _context.Notifications.Add(new Notification
        {
            RecipientUserId = recipientUserId,
            Type = NotificationType.FriendRequestReceived,
            RelatedUserId = requesterUserId
        });

        return Task.CompletedTask;
    }

    internal Task NotifyFriendRequestAcceptedAsync(Guid recipientUserId, Guid accepterUserId)
    {
        _context.Notifications.Add(new Notification
        {
            RecipientUserId = recipientUserId,
            Type = NotificationType.FriendRequestAccepted,
            RelatedUserId = accepterUserId
        });

        return Task.CompletedTask;
    }

    internal Task NotifyMissedCallAsync(Guid recipientUserId, Guid callerId)
    {
        _context.Notifications.Add(new Notification
        {
            RecipientUserId = recipientUserId,
            Type = NotificationType.MissedCall,
            RelatedUserId = callerId
        });

        return Task.CompletedTask;
    }

    internal Task NotifyMentionAsync(Guid recipientUserId, Guid mentionerUserId, Guid? serverId, Guid? channelId, Guid? conversationId, Guid messageId)
    {
        _context.Notifications.Add(new Notification
        {
            RecipientUserId = recipientUserId,
            Type = NotificationType.Mention,
            RelatedUserId = mentionerUserId,
            ContextServerId = serverId,
            ContextChannelId = channelId,
            ContextConversationId = conversationId,
            ContextMessageId = messageId
        });

        return Task.CompletedTask;
    }

    /// <summary>Fan-out for an <c>@everyone</c> trigger (P3) - one <see cref="Notification"/> row per
    /// current server member, batched via <c>AddRange</c> rather than one insert per member, since a
    /// large server could otherwise mean hundreds of individual round trips. No
    /// <see cref="Concord.Domain.Entities.MessageMention"/> rows are created here; see
    /// <see cref="Concord.Domain.Entities.Message.MentionsEveryone"/> for why.</summary>
    internal Task NotifyMentionsBulkAsync(List<Guid> recipientUserIds, Guid mentionerUserId, Guid serverId, Guid channelId, Guid messageId)
    {
        _context.Notifications.AddRange(recipientUserIds.Select(recipientUserId => new Notification
        {
            RecipientUserId = recipientUserId,
            Type = NotificationType.Mention,
            RelatedUserId = mentionerUserId,
            ContextServerId = serverId,
            ContextChannelId = channelId,
            ContextMessageId = messageId
        }));

        return Task.CompletedTask;
    }

    public async Task<PagedResult<NotificationResponse>> GetMyNotificationsAsync(Guid userId, int page, int pageSize)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        var notificationsQuery = _context.Notifications
            .Where(notification => notification.RecipientUserId == userId);

        var totalCount = await notificationsQuery.CountAsync();

        var notifications = await notificationsQuery
            .OrderByDescending(notification => notification.Created)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var relatedUserIds = notifications
            .Where(notification => notification.RelatedUserId.HasValue)
            .Select(notification => notification.RelatedUserId!.Value)
            .Distinct()
            .ToList();

        var usersById = await _context.Users
            .Where(user => relatedUserIds.Contains(user.Id))
            .ToDictionaryAsync(user => user.Id);

        return new PagedResult<NotificationResponse>
        {
            Items = notifications
                .Select(notification => notification.MapToResponse(
                    notification.RelatedUserId.HasValue ? usersById.GetValueOrDefault(notification.RelatedUserId.Value) : null))
                .ToList(),
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    public async Task MarkAsReadAsync(Guid userId, Guid notificationId)
    {
        var notification = await _context.Notifications
            .FirstOrDefaultAsync(notification => notification.Id == notificationId);

        if (notification is null || notification.RecipientUserId != userId)
            throw new NotificationNotFoundException();

        notification.IsRead = true;
        notification.ReadAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
    }

    public async Task MarkAllAsReadAsync(Guid userId)
    {
        await _context.Notifications
            .Where(notification => notification.RecipientUserId == userId && !notification.IsRead)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(notification => notification.IsRead, true)
                .SetProperty(notification => notification.ReadAt, DateTime.UtcNow));
    }
}
