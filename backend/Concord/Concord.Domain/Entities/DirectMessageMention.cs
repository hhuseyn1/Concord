namespace Concord.Domain.Entities;

public class DirectMessageMention : BaseEntity
{
    public Guid Id { get; set; }

    public Guid DirectMessageId { get; set; }
    public Guid MentionedUserId { get; set; }
}
