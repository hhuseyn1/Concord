using Concord.Application.Enums;

namespace Concord.Application.Realtime;

public interface INotificationsRealtimeNotifier
{
    Task NotifyAsync(
        Guid targetUserId,
        NotificationType type,
        Guid relatedUserId,
        Guid? contextServerId = null,
        Guid? contextChannelId = null,
        Guid? contextConversationId = null,
        Guid? contextMessageId = null);
}
