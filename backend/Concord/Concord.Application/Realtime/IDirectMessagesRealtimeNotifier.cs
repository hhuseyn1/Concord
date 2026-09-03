using Concord.Application.Models;

namespace Concord.Application.Realtime;

public interface IDirectMessagesRealtimeNotifier
{
    Task ConversationReadAsync(Guid conversationId, Guid recipientUserId, Guid userId, DateTime readAt);
    Task MessageReceivedAsync(Guid userAId, Guid userBId, DirectMessageResponse message);
    Task MessagePinnedAsync(Guid userAId, Guid userBId, DirectMessageResponse message);
    Task MessageUnpinnedAsync(Guid userAId, Guid userBId, DirectMessageResponse message);
    Task MessageEditedAsync(Guid userAId, Guid userBId, DirectMessageResponse message);
    Task MessageDeletedAsync(Guid userAId, Guid userBId, Guid conversationId, Guid messageId);
    Task MessageReactionsChangedAsync(Guid userAId, Guid userBId, DirectMessageResponse message);
}
