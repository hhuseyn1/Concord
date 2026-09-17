namespace Concord.Domain.Entities;

public class TwoFactorRecoveryCode : BaseEntity
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public string? CodeHash { get; set; }

    public DateTime? UsedAt { get; set; }
}
