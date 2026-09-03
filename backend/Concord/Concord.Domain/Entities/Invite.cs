namespace Concord.Domain.Entities;

public class Invite : BaseEntity
{
    public Guid Id { get; set; }

    public Guid ServerId { get; set; }

    public string? Code { get; set; }

    public Guid CreatedByUserId { get; set; }

    public DateTime? ExpiresAtUtc { get; set; }

    public int? MaxUses { get; set; }

    public int UseCount { get; set; }
}
