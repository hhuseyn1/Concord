namespace Concord.Domain.Entities;

/// <summary>
/// A user barred from rejoining a server (P1). A ban is deliberately *not* a <see cref="ServerMember"/>
/// with a flag: banning removes the membership row, so every existing membership check keeps working
/// unchanged and a banned user simply is not a member. This table is what stops them coming back
/// through an invite.
/// </summary>
public class ServerBan : BaseEntity
{
    public Guid Id { get; set; }

    public Guid ServerId { get; set; }
    public Guid UserId { get; set; }

    public Guid BannedByUserId { get; set; }

    public string? Reason { get; set; }

    /// <summary>
    /// When the ban lapses on its own, or <c>null</c> for a ban that lasts until it is lifted.
    /// Evaluated on read (see <c>ModerationService.IsBannedAsync</c>) rather than swept by a
    /// background job, so an expired ban needs no cleanup to stop applying.
    /// </summary>
    public DateTime? ExpiresAtUtc { get; set; }
}
