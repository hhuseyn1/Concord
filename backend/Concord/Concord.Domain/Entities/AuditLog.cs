namespace Concord.Domain.Entities;

/// <summary>
/// A queryable, compliance-style trail of admin/moderation actions - distinct from the existing
/// <c>ILogger</c> calls at the same call sites, which remain in place for ops/observability. This
/// table exists purely to be read back through <c>GET Admin/AuditLog</c>, so nothing here should ever
/// need to be mutated once written.
/// </summary>
public class AuditLog : BaseEntity
{
    public Guid Id { get; set; }

    public Guid ActorUserId { get; set; }

    /// <summary>A short stable identifier such as <c>"UserDisabled"</c> or <c>"MemberBanned"</c>, not a
    /// free-text sentence, so the admin UI can filter/group by it later.</summary>
    public string Action { get; set; } = null!;

    /// <summary>Plain string rather than <see cref="Application.Enums.ReportTargetType"/> - actions
    /// logged here target a wider range of things (users, servers, roles) than a report ever does, so
    /// a closed enum would need constant widening.</summary>
    public string? TargetType { get; set; }

    public Guid? TargetId { get; set; }

    /// <summary>JSON-serialized extra context (e.g. old/new role for a role change), or <c>null</c>
    /// when the action needs none.</summary>
    public string? Metadata { get; set; }
}
