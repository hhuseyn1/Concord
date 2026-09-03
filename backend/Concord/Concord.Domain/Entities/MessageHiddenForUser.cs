namespace Concord.Domain.Entities;

public class MessageHiddenForUser : BaseEntity
{
    public Guid Id { get; set; }

    public Guid MessageId { get; set; }
    public Guid UserId { get; set; }
}
