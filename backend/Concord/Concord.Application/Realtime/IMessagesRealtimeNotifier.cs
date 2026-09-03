using Concord.Application.Models;

namespace Concord.Application.Realtime;

public interface IMessagesRealtimeNotifier
{
    Task MessageReceivedAsync(Guid channelId, MessageResponse message);
    Task MessagePinnedAsync(Guid channelId, MessageResponse message);
    Task MessageUnpinnedAsync(Guid channelId, MessageResponse message);
    Task MessageEditedAsync(Guid channelId, MessageResponse message);
    Task MessageDeletedAsync(Guid channelId, Guid messageId);
    Task MessageReactionsChangedAsync(Guid channelId, MessageResponse message);
}
