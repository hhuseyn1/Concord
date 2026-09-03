using Concord.Application.Enums;

namespace Concord.Domain.Entities;

/// <summary>
/// A user- or message-report filed for moderator review. <see cref="TargetId"/> is deliberately a
/// bare Guid with no FK constraint - it can point at a channel message, a direct message, or a user,
/// three unrelated tables, so <c>ReportsService</c> validates existence itself at write time rather
/// than the database enforcing it.
/// </summary>
public class Report : BaseEntity
{
    public Guid Id { get; set; }

    public Guid ReporterUserId { get; set; }

    public ReportTargetType TargetType { get; set; }
    public Guid TargetId { get; set; }

    public string Reason { get; set; } = null!;

    public ReportStatus Status { get; set; }

    public Guid? ResolvedByUserId { get; set; }
    public DateTime? ResolvedAtUtc { get; set; }
}
