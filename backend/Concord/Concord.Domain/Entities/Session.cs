namespace Concord.Domain.Entities;

public class Session : BaseEntity
{
    public Session()
    {
        User = null!;
    }

    public Guid Id { get; set; }

    public Guid UserId { get; set; }
    public User User { get; set; }

    public Guid AccessTokenId { get; set; }
    public Guid RefreshTokenId { get; set; }
    public DateTime? Refreshed { get; set; }
    public DateTime Expires { get; set; }
    public bool IsPersistent { get; set; }

    public string? UserAgent { get; set; }
    public string? IpAddress { get; set; }
    public string? DeviceLabel { get; set; }
    public string? Browser { get; set; }
    public string? OS { get; set; }
}
