using Concord.Application.Enums;

namespace Concord.Domain.Entities;

public class Role : BaseEntity
{
    /// <summary>
    /// Baseline granted to every member through the auto-created default role - read, talk, and use
    /// voice, but nothing administrative. Mirrors what every member could do under the pre-RBAC
    /// owner/member split, so existing servers behave identically after the backfill.
    /// </summary>
    public const ServerPermission DefaultRolePermissions =
        ServerPermission.ViewChannels |
        ServerPermission.SendMessages |
        ServerPermission.Connect |
        ServerPermission.Speak;

    public Guid Id { get; set; }

    public Guid ServerId { get; set; }

    public string? Name { get; set; }

    /// <summary>Hex colour (<c>#RRGGBB</c>) used to tint member names, or <c>null</c> to inherit.</summary>
    public string? Color { get; set; }

    public ServerPermission Permissions { get; set; }

    /// <summary>
    /// Hierarchy rank - higher outranks lower. A member may only edit, delete, or assign roles
    /// strictly below their own highest position, which is what stops a moderator from granting
    /// themselves Administrator or acting on someone above them. The default role is always 0.
    /// </summary>
    public int Position { get; set; }

    /// <summary>
    /// Marks the server's <c>@everyone</c> role: created with the server, applies to every member
    /// without an explicit assignment row, and cannot be deleted or reassigned.
    /// </summary>
    public bool IsDefault { get; set; }
}
