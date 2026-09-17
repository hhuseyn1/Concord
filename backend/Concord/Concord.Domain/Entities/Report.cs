using Concord.Application.Enums;

namespace Concord.Domain.Entities;

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
