using Concord.Application.Enums;

namespace Concord.Domain.Entities;

public class PushToken : BaseEntity
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public string Token { get; set; } = null!;

    public PushPlatform Platform { get; set; }

    public DateTime LastSeenUtc { get; set; }
}
