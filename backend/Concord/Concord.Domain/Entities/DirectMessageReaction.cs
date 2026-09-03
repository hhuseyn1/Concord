namespace Concord.Domain.Entities;

/// <summary>Mirrors <see cref="Concord.Domain.Entities.MessageReaction"/> (M-01) for DM messages.</summary>
public class DirectMessageReaction : BaseEntity
{
    public Guid Id { get; set; }

    public Guid DirectMessageId { get; set; }
    public Guid UserId { get; set; }

    public string Emoji { get; set; } = string.Empty;
}
