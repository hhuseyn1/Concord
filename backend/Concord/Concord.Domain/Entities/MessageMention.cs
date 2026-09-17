namespace Concord.Domain.Entities;

public class MessageMention : BaseEntity
{
    public Guid Id { get; set; }

    public Guid MessageId { get; set; }
    public Guid MentionedUserId { get; set; }
}
