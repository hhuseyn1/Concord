namespace Concord.Domain.Entities;

public class AuditLog : BaseEntity
{
    public Guid Id { get; set; }

    public Guid ActorUserId { get; set; }

    public string Action { get; set; } = null!;

    public string? TargetType { get; set; }

    public Guid? TargetId { get; set; }

    public string? Metadata { get; set; }
}
