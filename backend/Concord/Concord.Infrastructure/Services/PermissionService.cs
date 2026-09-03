using Concord.Application.Enums;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Services;

/// <summary>
/// Resolves what a member may do in a server (P0 RBAC). Deliberately depends on nothing but the
/// <see cref="ApplicationDbContext"/> - <see cref="ServersService"/>, <see cref="ChannelsService"/>,
/// <see cref="MessagesService"/>, and <see cref="VoiceService"/> all consume it, so any dependency
/// of its own would close a cycle in the DI graph.
/// </summary>
public class PermissionService(ApplicationDbContext context)
{
    /// <summary>Every declared flag OR'd together - what an owner or an Administrator holds.</summary>
    public static readonly ServerPermission All = Enum
        .GetValues<ServerPermission>()
        .Aggregate(ServerPermission.None, (accumulated, permission) => accumulated | permission);

    /// <summary>Sentinel rank for the owner, who outranks every role by definition.</summary>
    public const int OwnerPosition = int.MaxValue;

    private readonly ApplicationDbContext _context = context;

    /// <summary>
    /// Effective permissions and hierarchy rank for one member. Assumes membership has already been
    /// verified by the caller (every call site reaches this through <c>AssertServerMemberAsync</c>).
    /// </summary>
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

        // Administrator is a shorthand for "everything", including permissions added in later phases.
        if (permissions.HasFlag(ServerPermission.Administrator))
            permissions = All;

        var highestPosition = assignedRoles.Count == 0 ? 0 : assignedRoles.Max(role => role.Position);

        // P1 moderation is subtractive and applied last, so it overrides whatever the roles granted -
        // including Administrator. Doing it here rather than at each call site means every existing
        // permission check (message send, voice token, pin, ...) honours a mute or timeout without
        // needing to know those features exist.
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

        // Report the moderation state rather than the raw missing flag when moderation is what took
        // it away - "you lack SendMessages" is actively misleading to someone who is timed out and
        // whose role does grant it.
        var missing = required & ~resolved.Permissions;

        if (resolved.TimedOutUntil is { } until && (missing & (ServerPermission.SendMessages | ServerPermission.Speak)) != ServerPermission.None)
            throw new MemberTimedOutException(until);

        if (resolved.IsMuted && missing == ServerPermission.Speak)
            throw new MemberMutedException();

        throw new MissingPermissionException(required);
    }

    /// <summary>
    /// Hierarchy gate for member-targeted actions (kick today; ban, mute, and timeout in P1). The
    /// owner may act on anyone, nobody may act on the owner, and otherwise the actor must rank
    /// strictly above the target - equal rank is not enough, which is what stops two moderators from
    /// removing each other.
    /// </summary>
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

    /// <summary>
    /// Hierarchy gate for role-targeted actions - editing, deleting, or assigning a role requires
    /// outranking it, so ManageRoles cannot be escalated into Administrator.
    /// </summary>
    public async Task AssertCanManageRoleAsync(Guid actorUserId, Server server, Role role)
    {
        if (server.OwnerId == actorUserId)
            return;

        var actor = await ResolveAsync(actorUserId, server);

        if (actor.HighestRolePosition <= role.Position)
            throw new RoleHierarchyException();
    }

    /// <summary>
    /// Effective permissions of a member, the rank every hierarchy check compares against, and the
    /// P1 moderation state that produced any subtraction - carried so callers can explain *why* a
    /// permission is missing instead of just refusing.
    /// </summary>
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
