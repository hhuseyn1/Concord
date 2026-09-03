using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Domain.Entities;

namespace Concord.Infrastructure.Extensions;

public static class RoleExtensions
{
    public static RoleResponse MapToResponse(this Role role, int memberCount = 0) => new()
    {
        Id = role.Id,
        ServerId = role.ServerId,
        Name = role.Name,
        Color = role.Color,
        Permissions = (long)role.Permissions,
        PermissionNames = role.Permissions.ToPermissionNames(),
        Position = role.Position,
        IsDefault = role.IsDefault,
        MemberCount = memberCount
    };

    /// <summary>
    /// Splits a bitfield into its individual flag names. <c>Enum.ToString()</c> on a combined value
    /// would collapse to "All"-style aliases and yields a single comma-joined string, so the flags
    /// are tested one by one instead.
    /// </summary>
    public static List<string> ToPermissionNames(this ServerPermission permissions) => Enum
        .GetValues<ServerPermission>()
        .Where(permission => permission != ServerPermission.None && permissions.HasFlag(permission))
        .Select(permission => permission.ToString())
        .ToList();
}
