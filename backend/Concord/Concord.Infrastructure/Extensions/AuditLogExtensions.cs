using Concord.Application.Models;
using Concord.Domain.Entities;

namespace Concord.Infrastructure.Extensions;

public static class AuditLogExtensions
{
    public static AuditLogResponse MapToResponse(this AuditLog auditLog, User actor) => new()
    {
        Id = auditLog.Id,
        Actor = actor.MapToPublicModel(),
        Action = auditLog.Action,
        TargetType = auditLog.TargetType,
        TargetId = auditLog.TargetId,
        Metadata = auditLog.Metadata,
        CreatedUtc = auditLog.Created
    };
}
