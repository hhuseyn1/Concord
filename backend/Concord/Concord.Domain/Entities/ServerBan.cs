namespace Concord.Domain.Entities;

public class ServerBan : BaseEntity
{
    public Guid Id { get; set; }

    public Guid ServerId { get; set; }
    public Guid UserId { get; set; }

    public Guid BannedByUserId { get; set; }

    public string? Reason { get; set; }

    public DateTime? ExpiresAtUtc { get; set; }
}
