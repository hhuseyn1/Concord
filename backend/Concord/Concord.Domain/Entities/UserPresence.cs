using Concord.Application.Enums;

namespace Concord.Domain.Entities;

public class UserPresence : BaseEntity
{
    public Guid UserId { get; set; }

    public PresenceStatus Status { get; set; } = PresenceStatus.Offline;

    public DateTime? LastSeenAt { get; set; }
}
