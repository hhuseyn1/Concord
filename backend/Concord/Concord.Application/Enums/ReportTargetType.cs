namespace Concord.Application.Enums;

/// <summary>What a <see cref="Concord.Domain.Entities.Report"/> points at. <c>TargetId</c> is a bare
/// Guid with no FK constraint, since it can reference either a message (channel or DM) or a user -
/// existence and access are checked in <c>ReportsService</c> instead.</summary>
public enum ReportTargetType
{
    Message,
    User
}
