namespace Concord.Domain.Entities;

public class PasswordResetToken : BaseEntity
{
    public PasswordResetToken()
    {
        User = null!;
    }

    public Guid Id { get; set; }

    public Guid UserId { get; set; }
    public User User { get; set; }

    public string TokenHash { get; set; } = null!;
    public DateTime ExpiresAt { get; set; }
    public bool Used { get; set; }
}
