namespace Concord.Domain.Entities;

public class ServerMember : BaseEntity
{
    public Guid Id { get; set; }

    public Guid ServerId { get; set; }
    public Guid UserId { get; set; }

    /// <summary>
    /// Server mute (P1): the member keeps <see cref="Enums.ServerPermission.Connect"/> but loses
    /// <see cref="Enums.ServerPermission.Speak"/>, so they stay in voice as a listener. A toggle
    /// rather than a duration - use a timeout for the time-boxed case.
    /// </summary>
    public bool IsMuted { get; set; }

    /// <summary>
    /// Timeout (P1): while this is in the future the member loses
    /// <see cref="Enums.ServerPermission.SendMessages"/> and <see cref="Enums.ServerPermission.Speak"/>.
    /// Like <see cref="ServerBan.ExpiresAtUtc"/> this is evaluated on read, so a lapsed timeout stops
    /// applying with no sweep and no scheduler.
    /// </summary>
    public DateTime? TimedOutUntil { get; set; }

    /// <summary>Who applied the timeout, for the moderation view. Cleared when it is lifted.</summary>
    public Guid? TimedOutByUserId { get; set; }

    /// <summary>Free-text note shown in the moderation list. Cleared when the timeout is lifted.</summary>
    public string? TimeoutReason { get; set; }
}
