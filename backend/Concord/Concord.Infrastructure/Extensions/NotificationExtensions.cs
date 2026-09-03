using Concord.Application.Models;
using Concord.Domain.Entities;

namespace Concord.Infrastructure.Extensions;

public static class NotificationExtensions
{
    public static NotificationResponse MapToResponse(this Notification notification, User? relatedUser) => new()
    {
        Id = notification.Id,
        Type = notification.Type,
        RelatedUser = relatedUser?.MapToPublicModel(),
        IsRead = notification.IsRead,
        ReadAt = notification.ReadAt,
        Created = notification.Created,
        ContextServerId = notification.ContextServerId,
        ContextChannelId = notification.ContextChannelId,
        ContextConversationId = notification.ContextConversationId,
        ContextMessageId = notification.ContextMessageId
    };
}
