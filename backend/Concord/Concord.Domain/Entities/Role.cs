using Concord.Application.Enums;

namespace Concord.Domain.Entities;

public class Role : BaseEntity
{
    public const ServerPermission DefaultRolePermissions =
        ServerPermission.ViewChannels |
        ServerPermission.SendMessages |
        ServerPermission.Connect |
        ServerPermission.Speak;

    public Guid Id { get; set; }

    public Guid ServerId { get; set; }

    public string? Name { get; set; }

    public string? Color { get; set; }

    public ServerPermission Permissions { get; set; }

    public int Position { get; set; }

    public bool IsDefault { get; set; }
}
