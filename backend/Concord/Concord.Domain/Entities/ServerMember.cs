namespace Concord.Domain.Entities;

public class ServerMember : BaseEntity
{
    public Guid Id { get; set; }

    public Guid ServerId { get; set; }
    public Guid UserId { get; set; }

    public bool IsMuted { get; set; }

    public DateTime? TimedOutUntil { get; set; }

    public Guid? TimedOutByUserId { get; set; }

    public string? TimeoutReason { get; set; }
}
