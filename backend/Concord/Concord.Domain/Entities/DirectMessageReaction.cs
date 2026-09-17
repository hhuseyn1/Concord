namespace Concord.Domain.Entities;

public class DirectMessageReaction : BaseEntity
{
    public Guid Id { get; set; }

    public Guid DirectMessageId { get; set; }
    public Guid UserId { get; set; }

    public string Emoji { get; set; } = string.Empty;
}
