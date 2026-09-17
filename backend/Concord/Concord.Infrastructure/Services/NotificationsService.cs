using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Application.Push;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Extensions;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Services;

public class NotificationsService(ApplicationDbContext context, IPushNotificationSender pushNotificationSender)
{
    private readonly ApplicationDbContext _context = context;
    private readonly IPushNotificationSender _pushNotificationSender = pushNotificationSender;

    internal async Task NotifyFriendRequestReceivedAsync(Guid recipientUserId, Guid requesterUserId)
    {
        _context.Notifications.Add(new Notification
        {
            RecipientUserId = recipientUserId,
            Type = NotificationType.FriendRequestReceived,
            RelatedUserId = requesterUserId
        });

        await SendPushAsync(recipientUserId, requesterUserId, NotificationType.FriendRequestReceived);
    }

    internal async Task NotifyFriendRequestAcceptedAsync(Guid recipientUserId, Guid accepterUserId)
    {
        _context.Notifications.Add(new Notification
        {
            RecipientUserId = recipientUserId,
            Type = NotificationType.FriendRequestAccepted,
            RelatedUserId = accepterUserId
        });

        await SendPushAsync(recipientUserId, accepterUserId, NotificationType.FriendRequestAccepted);
    }

    internal void NotifyReportDismissed(Guid reporterUserId, string? reason)
    {
        _context.Notifications.Add(new Notification
        {
            RecipientUserId = reporterUserId,
            Type = NotificationType.ReportDismissed,
            Reason = reason
        });
    }

    internal async Task NotifyMissedCallAsync(Guid recipientUserId, Guid callerId)
    {
        _context.Notifications.Add(new Notification
        {
            RecipientUserId = recipientUserId,
            Type = NotificationType.MissedCall,
            RelatedUserId = callerId
        });

        await SendPushAsync(recipientUserId, callerId, NotificationType.MissedCall);
    }

    internal async Task NotifyDirectMessageReceivedAsync(
        Guid recipientUserId, Guid senderId, Guid conversationId, Guid messageId, string? messageContent = null)
    {
        _context.Notifications.Add(new Notification
        {
            RecipientUserId = recipientUserId,
            Type = NotificationType.DirectMessageReceived,
            RelatedUserId = senderId,
            ContextConversationId = conversationId,
            ContextMessageId = messageId
        });

        await SendPushAsync(recipientUserId, senderId, NotificationType.DirectMessageReceived, messageContent);
    }

    internal async Task NotifyMentionAsync(
        Guid recipientUserId, Guid mentionerUserId, Guid? serverId, Guid? channelId, Guid? conversationId, Guid messageId,
        string? messageContent = null)
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

        await SendPushAsync(recipientUserId, mentionerUserId, NotificationType.Mention, messageContent);
    }

    private async Task SendPushAsync(Guid recipientUserId, Guid relatedUserId, NotificationType type, string? messageContent = null)
    {
        var recipientLocale = await _context.Users
            .Where(user => user.Id == recipientUserId)
            .Select(user => user.Locale)
            .FirstOrDefaultAsync();

        if (recipientLocale is null) return;

        var relatedUser = await _context.Users
            .Where(user => user.Id == relatedUserId)
            .Select(user => new { user.Username, user.Name, user.Surname })
            .FirstOrDefaultAsync();

        var name = relatedUser?.Username;
        if (string.IsNullOrWhiteSpace(name)) name = $"{relatedUser?.Name} {relatedUser?.Surname}".Trim();
        if (string.IsNullOrWhiteSpace(name)) name = "Someone";

        await _pushNotificationSender.SendAsync(recipientUserId, name, BuildPushBody(type, recipientLocale, messageContent));
    }

    private const int MessagePreviewMaxLength = 120;

    private static string BuildPushBody(NotificationType type, string locale, string? messageContent)
    {
        var isAzerbaijani = locale.StartsWith("az", StringComparison.OrdinalIgnoreCase);

        if (type is NotificationType.DirectMessageReceived or NotificationType.Mention)
        {
            if (!string.IsNullOrWhiteSpace(messageContent))
            {
                var trimmed = messageContent.Trim();
                return trimmed.Length > MessagePreviewMaxLength
                    ? string.Concat(trimmed.AsSpan(0, MessagePreviewMaxLength), "…")
                    : trimmed;
            }

            return isAzerbaijani ? "📎 Fayl göndərdi" : "📎 Sent an attachment";
        }

        return (type, isAzerbaijani) switch
        {
            (NotificationType.FriendRequestReceived, true) => "sizə dostluq sorğusu göndərdi",
            (NotificationType.FriendRequestReceived, false) => "sent you a friend request",
            (NotificationType.FriendRequestAccepted, true) => "dostluq sorğunuzu qəbul etdi",
            (NotificationType.FriendRequestAccepted, false) => "accepted your friend request",
            (NotificationType.MissedCall, true) => "sizə zəng etdi (buraxılmış zəng)",
            (NotificationType.MissedCall, false) => "missed your call",
            (NotificationType.ReportDismissed, true) => "hesabatınız nəzərdən keçirildi",
            (NotificationType.ReportDismissed, false) => "Your report was reviewed",
            (_, true) => "yeni bildiriş",
            (_, false) => "sent you a notification",
        };
    }

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
