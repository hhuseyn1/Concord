using Concord.Application.Enums;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Services;

public class PermissionService(ApplicationDbContext context)
{
    public static readonly ServerPermission All = Enum
        .GetValues<ServerPermission>()
        .Aggregate(ServerPermission.None, (accumulated, permission) => accumulated | permission);

    public const int OwnerPosition = int.MaxValue;

    private readonly ApplicationDbContext _context = context;

    public async Task<ResolvedPermissions> ResolveAsync(Guid userId, Server server)
    {
        if (server.OwnerId == userId)
            return new ResolvedPermissions(All, OwnerPosition, IsOwner: true);

        var moderation = await _context.ServerMembers
            .Where(member => member.ServerId == server.Id && member.UserId == userId)
            .Select(member => new { member.IsMuted, member.TimedOutUntil })
            .FirstOrDefaultAsync();

        var defaultPermissions = await _context.Roles
            .Where(role => role.ServerId == server.Id && role.IsDefault)
            .Select(role => role.Permissions)
            .FirstOrDefaultAsync();

        var assignedRoles = await _context.ServerMembers
            .Where(member => member.ServerId == server.Id && member.UserId == userId)
            .Join(_context.ServerMemberRoles,
                member => member.Id,
                assignment => assignment.ServerMemberId,
                (member, assignment) => assignment.RoleId)
            .Join(_context.Roles,
                roleId => roleId,
                role => role.Id,
                (roleId, role) => new { role.Permissions, role.Position })
            .ToListAsync();

        var permissions = assignedRoles.Aggregate(defaultPermissions, (accumulated, role) => accumulated | role.Permissions);

        if (permissions.HasFlag(ServerPermission.Administrator))
            permissions = All;

        var highestPosition = assignedRoles.Count == 0 ? 0 : assignedRoles.Max(role => role.Position);

        var isTimedOut = moderation?.TimedOutUntil is { } until && until > DateTime.UtcNow;
        var isMuted = moderation?.IsMuted ?? false;

        if (isTimedOut)
            permissions &= ~(ServerPermission.SendMessages | ServerPermission.Speak);

        if (isMuted)
            permissions &= ~ServerPermission.Speak;

        return new ResolvedPermissions(
            permissions,
            highestPosition,
            IsOwner: false,
            IsMuted: isMuted,
            TimedOutUntil: isTimedOut ? moderation!.TimedOutUntil : null);
    }

    public async Task<ResolvedPermissions> ResolveAsync(Guid userId, Guid serverId)
    {
        var server = await _context.Servers.FirstOrDefaultAsync(server => server.Id == serverId)
            ?? throw new ServerNotFoundException();

        return await ResolveAsync(userId, server);
    }

    public async Task AssertPermissionAsync(Guid userId, Server server, ServerPermission required)
    {
        var resolved = await ResolveAsync(userId, server);

        if (resolved.Has(required))
            return;

        var missing = required & ~resolved.Permissions;

        if (resolved.TimedOutUntil is { } until && (missing & (ServerPermission.SendMessages | ServerPermission.Speak)) != ServerPermission.None)
            throw new MemberTimedOutException(until);

        if (resolved.IsMuted && missing == ServerPermission.Speak)
            throw new MemberMutedException();

        throw new MissingPermissionException(required);
    }

    public async Task AssertCanActOnMemberAsync(Guid actorUserId, Guid targetUserId, Server server)
    {
        if (actorUserId == targetUserId)
            throw new CannotTargetSelfException();

        if (server.OwnerId == actorUserId)
            return;

        if (server.OwnerId == targetUserId)
            throw new RoleHierarchyException();

        var actor = await ResolveAsync(actorUserId, server);
        var target = await ResolveAsync(targetUserId, server);

        if (actor.HighestRolePosition <= target.HighestRolePosition)
            throw new RoleHierarchyException();
    }

    public async Task AssertCanManageRoleAsync(Guid actorUserId, Server server, Role role)
    {
        if (server.OwnerId == actorUserId)
            return;

        var actor = await ResolveAsync(actorUserId, server);

        if (actor.HighestRolePosition <= role.Position)
            throw new RoleHierarchyException();
    }

    public record ResolvedPermissions(
        ServerPermission Permissions,
        int HighestRolePosition,
        bool IsOwner,
        bool IsMuted = false,
        DateTime? TimedOutUntil = null)
    {
        public bool Has(ServerPermission required) => (Permissions & required) == required;
    }
}
