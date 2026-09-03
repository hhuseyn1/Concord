using Concord.Application.Auditing;
using Concord.Domain.Entities;
using Concord.Infrastructure.Context;

namespace Concord.Infrastructure.Services;

public class AuditLogService(ApplicationDbContext context) : IAuditLogService
{
    private readonly ApplicationDbContext _context = context;

    public async Task LogAsync(Guid actorUserId, string action, string? targetType = null, Guid? targetId = null, string? metadata = null)
    {
        _context.AuditLogs.Add(new AuditLog
        {
            ActorUserId = actorUserId,
            Action = action,
            TargetType = targetType,
            TargetId = targetId,
            Metadata = metadata
        });

        await _context.SaveChangesAsync();
    }
}
