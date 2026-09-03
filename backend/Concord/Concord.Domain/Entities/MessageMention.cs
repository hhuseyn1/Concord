namespace Concord.Domain.Entities;

/// <summary>One user mentioned (P2.2) in one channel message via `@username`. Mirrors the dual-table
/// <see cref="MessageReaction"/>/<see cref="DirectMessageReaction"/> pattern - no shared base table
/// exists between <see cref="Message"/> and <see cref="DirectMessage"/>, so this is channel-only,
/// with <see cref="DirectMessageMention"/> as its DM counterpart.</summary>
public class MessageMention : BaseEntity
{
    public Guid Id { get; set; }

    public Guid MessageId { get; set; }
    public Guid MentionedUserId { get; set; }
}
