using Concord.API.Hubs;
using Concord.Application.Models;
using Concord.Application.Realtime;
using Microsoft.AspNetCore.SignalR;

namespace Concord.API.Realtime;

public class SignalRMessagesNotifier(IHubContext<MessagesHub> hubContext) : IMessagesRealtimeNotifier
{
    private readonly IHubContext<MessagesHub> _hubContext = hubContext;

    public async Task MessageReceivedAsync(Guid channelId, MessageResponse message)
    {
        await _hubContext.Clients.Group($"Channel:{channelId}").SendAsync("MessageReceived", message);
    }

    public async Task MessagePinnedAsync(Guid channelId, MessageResponse message)
    {
        await _hubContext.Clients.Group($"Channel:{channelId}").SendAsync("MessagePinned", message);
    }

    public async Task MessageUnpinnedAsync(Guid channelId, MessageResponse message)
    {
        await _hubContext.Clients.Group($"Channel:{channelId}").SendAsync("MessageUnpinned", message);
    }

    public async Task MessageEditedAsync(Guid channelId, MessageResponse message)
    {
        await _hubContext.Clients.Group($"Channel:{channelId}").SendAsync("MessageEdited", message);
    }

    public async Task MessageDeletedAsync(Guid channelId, Guid messageId)
    {
        await _hubContext.Clients.Group($"Channel:{channelId}").SendAsync("MessageDeleted", messageId);
    }

    public async Task MessageReactionsChangedAsync(Guid channelId, MessageResponse message)
    {
        await _hubContext.Clients.Group($"Channel:{channelId}").SendAsync("MessageReactionsChanged", message);
    }
}
