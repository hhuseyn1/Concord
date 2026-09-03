using Concord.Application.Models;
using Concord.Domain.Entities;

namespace Concord.Infrastructure.Extensions;

public static class ConversationExtensions
{
    public static ConversationResponse MapToResponse(
        this Conversation conversation,
        PublicProfileResponse otherUser,
        DirectMessageResponse? lastMessage,
        int unreadCount) => new()
    {
        Id = conversation.Id,
        OtherUser = otherUser,
        LastMessage = lastMessage,
        LastMessageAt = conversation.LastMessageAt,
        UnreadCount = unreadCount
    };
}
