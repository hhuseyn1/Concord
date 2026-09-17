namespace Concord.Application.Auditing;

public interface IAuditLogService
{
    Task LogAsync(Guid actorUserId, string action, string? targetType = null, Guid? targetId = null, string? metadata = null);
}
