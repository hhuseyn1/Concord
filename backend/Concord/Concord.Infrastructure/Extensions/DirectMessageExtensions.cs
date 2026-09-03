using Concord.Application.Models;
using Concord.Domain.Entities;

namespace Concord.Infrastructure.Extensions;

public static class DirectMessageExtensions
{
    public static DirectMessageResponse MapToResponse(
        this DirectMessage message,
        User sender,
        UserPresence? presence,
        List<ReactionSummaryResponse>? reactions = null,
        List<Guid>? mentionedUserIds = null) => new()
    {
        Id = message.Id,
        ConversationId = message.ConversationId,
        Sender = sender.MapToPublicModel(presence),
        Content = message.Content,
        Created = message.Created,
        EditedAtUtc = message.EditedAtUtc,
        AttachmentUrl = message.AttachmentUrl,
        ReplyToMessageId = message.ReplyToMessageId,
        Reactions = reactions ?? [],
        PinnedAt = message.PinnedAt,
        PinnedByUserId = message.PinnedByUserId,
        ForwardedFromSenderId = message.ForwardedFromSenderId,
        ForwardedFromCreatedAt = message.ForwardedFromCreatedAt,
        MentionedUserIds = mentionedUserIds ?? []
    };
}
