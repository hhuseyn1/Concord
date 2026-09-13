using Concord.API.Hubs;
using Concord.Application.Enums;
using Concord.Application.Realtime;
using Microsoft.AspNetCore.SignalR;

namespace Concord.API.Realtime;

public class SignalRNotificationsNotifier(IHubContext<NotificationsHub> hubContext) : INotificationsRealtimeNotifier
{
    private readonly IHubContext<NotificationsHub> _hubContext = hubContext;

    public async Task NotifyAsync(
        Guid targetUserId,
        NotificationType type,
        Guid? relatedUserId,
        Guid? contextServerId = null,
        Guid? contextChannelId = null,
        Guid? contextConversationId = null,
        Guid? contextMessageId = null,
        string? reason = null)
    {
        await _hubContext.Clients.User(targetUserId.ToString()).SendAsync("NotificationCreated", new
        {
            type,
            relatedUserId,
            created = DateTime.UtcNow,
            contextServerId,
            contextChannelId,
            contextConversationId,
            contextMessageId,
            reason
        });
    }
}
