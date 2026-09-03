namespace Concord.Domain.Entities;

public class Block : BaseEntity
{
    public Guid Id { get; set; }

    public Guid BlockerId { get; set; }
    public Guid BlockedId { get; set; }
}
