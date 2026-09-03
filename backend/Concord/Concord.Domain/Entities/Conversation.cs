namespace Concord.Domain.Entities;

public class Conversation : BaseEntity
{
    public Guid Id { get; set; }

    public Guid UserAId { get; set; }
    public Guid UserBId { get; set; }

    public DateTime? LastMessageAt { get; set; }

    public DateTime? LastReadAtA { get; set; }
    public DateTime? LastReadAtB { get; set; }
}
