using Concord.API.Hubs;
using Concord.Application.Models;
using Concord.Application.Realtime;
using Microsoft.AspNetCore.SignalR;

namespace Concord.API.Realtime;

public class SignalRDirectMessagesNotifier(IHubContext<DirectMessagesHub> hubContext) : IDirectMessagesRealtimeNotifier
{
    private readonly IHubContext<DirectMessagesHub> _hubContext = hubContext;

    public async Task ConversationReadAsync(Guid conversationId, Guid recipientUserId, Guid userId, DateTime readAt)
    {
        await _hubContext.Clients.User(recipientUserId.ToString())
            .SendAsync("ConversationRead", new { conversationId, userId, readAt });
    }

    public async Task MessageReceivedAsync(Guid userAId, Guid userBId, DirectMessageResponse message)
    {
        await _hubContext.Clients.Users([userAId.ToString(), userBId.ToString()]).SendAsync("DirectMessageReceived", message);
    }

    public async Task MessagePinnedAsync(Guid userAId, Guid userBId, DirectMessageResponse message)
    {
        await _hubContext.Clients.Users([userAId.ToString(), userBId.ToString()]).SendAsync("DirectMessagePinned", message);
    }

    public async Task MessageUnpinnedAsync(Guid userAId, Guid userBId, DirectMessageResponse message)
    {
        await _hubContext.Clients.Users([userAId.ToString(), userBId.ToString()]).SendAsync("DirectMessageUnpinned", message);
    }

    public async Task MessageEditedAsync(Guid userAId, Guid userBId, DirectMessageResponse message)
    {
        await _hubContext.Clients.Users([userAId.ToString(), userBId.ToString()]).SendAsync("DirectMessageEdited", message);
    }

    public async Task MessageDeletedAsync(Guid userAId, Guid userBId, Guid conversationId, Guid messageId)
    {
        await _hubContext.Clients.Users([userAId.ToString(), userBId.ToString()])
            .SendAsync("DirectMessageDeleted", new { conversationId, messageId });
    }

    public async Task MessageReactionsChangedAsync(Guid userAId, Guid userBId, DirectMessageResponse message)
    {
        await _hubContext.Clients.Users([userAId.ToString(), userBId.ToString()]).SendAsync("DirectMessageReactionsChanged", message);
    }
}
