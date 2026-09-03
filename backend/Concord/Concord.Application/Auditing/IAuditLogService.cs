namespace Concord.Application.Auditing;

/// <summary>
/// A thin, insert-only writer for the compliance-style audit trail (see <c>Concord.Domain.Entities.AuditLog</c>).
/// Deliberately a single method - this is not a queue or an event bus, just a place for admin/moderation
/// call sites to additionally record what they already log via <c>ILogger</c>.
/// </summary>
public interface IAuditLogService
{
    Task LogAsync(Guid actorUserId, string action, string? targetType = null, Guid? targetId = null, string? metadata = null);
}
