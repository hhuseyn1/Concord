namespace Concord.Domain.Entities;

/// <summary>Mirrors <see cref="MessageMention"/> for direct messages (P2.2).</summary>
public class DirectMessageMention : BaseEntity
{
    public Guid Id { get; set; }

    public Guid DirectMessageId { get; set; }
    public Guid MentionedUserId { get; set; }
}
