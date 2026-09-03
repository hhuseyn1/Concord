namespace Concord.Domain.Entities;

public class DirectMessageHiddenForUser : BaseEntity
{
    public Guid Id { get; set; }

    public Guid DirectMessageId { get; set; }
    public Guid UserId { get; set; }
}
