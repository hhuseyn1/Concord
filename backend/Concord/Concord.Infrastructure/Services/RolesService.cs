using System.Text.RegularExpressions;
using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Extensions;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Services;

public partial class RolesService(
    ApplicationDbContext context,
    ServersService serversService,
    PermissionService permissionService)
{
    private const int MaxRolesPerServer = 50;
    private const string DefaultRoleName = "@everyone";

    private readonly ApplicationDbContext _context = context;
    private readonly ServersService _serversService = serversService;
    private readonly PermissionService _permissionService = permissionService;

    [GeneratedRegex("^#[0-9A-Fa-f]{6}$")]
    private static partial Regex HexColorRegex();

    public static Role BuildDefaultRole(Guid serverId) => new()
    {
        ServerId = serverId,
        Name = DefaultRoleName,
        Permissions = Role.DefaultRolePermissions,
        Position = 0,
        IsDefault = true
    };

    public async Task<List<RoleResponse>> GetRolesAsync(Guid currentUserId, Guid serverId)
    {
        await _serversService.AssertServerMemberAsync(currentUserId, serverId);

        var roles = await _context.Roles
            .Where(role => role.ServerId == serverId)
            .OrderByDescending(role => role.Position)
            .ToListAsync();

        var roleIds = roles.Select(role => role.Id).ToList();

        var memberCountsByRoleId = await _context.ServerMemberRoles
            .Where(assignment => roleIds.Contains(assignment.RoleId))
            .GroupBy(assignment => assignment.RoleId)
            .Select(group => new { RoleId = group.Key, Count = group.Count() })
            .ToDictionaryAsync(entry => entry.RoleId, entry => entry.Count);

        var totalMembers = await _context.ServerMembers.CountAsync(member => member.ServerId == serverId);

        return roles
            .Select(role => role.MapToResponse(role.IsDefault ? totalMembers : memberCountsByRoleId.GetValueOrDefault(role.Id)))
            .ToList();
    }

    public async Task<MyServerPermissionsResponse> GetMyPermissionsAsync(Guid currentUserId, Guid serverId)
    {
        var server = await _serversService.AssertServerMemberAsync(currentUserId, serverId);

        var resolved = await _permissionService.ResolveAsync(currentUserId, server);

        return new MyServerPermissionsResponse
        {
            ServerId = serverId,
            IsOwner = resolved.IsOwner,
            Permissions = (long)resolved.Permissions,
            PermissionNames = resolved.Permissions.ToPermissionNames(),
            HighestRolePosition = resolved.HighestRolePosition,
            IsMuted = resolved.IsMuted,
            TimedOutUntil = resolved.TimedOutUntil
        };
    }

    public async Task<RoleResponse> CreateRoleAsync(Guid currentUserId, Guid serverId, CreateRoleRequest request)
    {
        var server = await _serversService.AssertPermissionAsync(currentUserId, serverId, ServerPermission.ManageRoles);

        ValidateName(request.Name);
        ValidateColor(request.Color);

        var permissions = ValidatePermissions(request.Permissions);

        await AssertCanGrantAsync(currentUserId, server, permissions);

        var roleCount = await _context.Roles.CountAsync(role => role.ServerId == serverId);

        if (roleCount >= MaxRolesPerServer)
            throw new ParameterValidationException(nameof(request.Name));

        var highestPosition = await _context.Roles
            .Where(role => role.ServerId == serverId)
            .MaxAsync(role => (int?)role.Position) ?? 0;

        var role = new Role
        {
            ServerId = serverId,
            Name = request.Name,
            Color = request.Color,
            Permissions = permissions,
            Position = highestPosition + 1,
            IsDefault = false
        };

        _context.Roles.Add(role);

        await _context.SaveChangesAsync();

        return role.MapToResponse();
    }

    public async Task<RoleResponse> UpdateRoleAsync(Guid currentUserId, Guid serverId, Guid roleId, UpdateRoleRequest request)
    {
        var server = await _serversService.AssertPermissionAsync(currentUserId, serverId, ServerPermission.ManageRoles);
        var role = await GetRoleInServerAsync(serverId, roleId);

        ValidateColor(request.Color);

        var permissions = ValidatePermissions(request.Permissions);

        await _permissionService.AssertCanManageRoleAsync(currentUserId, server, role);
        await AssertCanGrantAsync(currentUserId, server, permissions);

        if (!role.IsDefault)
        {
            ValidateName(request.Name);

            role.Name = request.Name;
            role.Color = request.Color;
        }

        role.Permissions = permissions;

        await _context.SaveChangesAsync();

        return role.MapToResponse();
    }

    public async Task DeleteRoleAsync(Guid currentUserId, Guid serverId, Guid roleId)
    {
        var server = await _serversService.AssertPermissionAsync(currentUserId, serverId, ServerPermission.ManageRoles);
        var role = await GetRoleInServerAsync(serverId, roleId);

        if (role.IsDefault)
            throw new CannotModifyDefaultRoleException();

        await _permissionService.AssertCanManageRoleAsync(currentUserId, server, role);

        _context.Roles.Remove(role);

        await _context.SaveChangesAsync();
    }

    public async Task ReorderRolesAsync(Guid currentUserId, Guid serverId, ReorderRolesRequest request)
    {
        var server = await _serversService.AssertPermissionAsync(currentUserId, serverId, ServerPermission.ManageRoles);

        var roles = await _context.Roles
            .Where(role => role.ServerId == serverId && !role.IsDefault)
            .ToListAsync();

        if (request.RoleIds.Count != roles.Count || request.RoleIds.Distinct().Count() != request.RoleIds.Count)
            throw new ParameterValidationException(nameof(request.RoleIds));

        var rolesById = roles.ToDictionary(role => role.Id);

        if (request.RoleIds.Any(roleId => !rolesById.ContainsKey(roleId)))
            throw new RoleNotFoundException();

        foreach (var role in roles)
            await _permissionService.AssertCanManageRoleAsync(currentUserId, server, role);

        for (var index = 0; index < request.RoleIds.Count; index++)
            rolesById[request.RoleIds[index]].Position = index + 1;

        await _context.SaveChangesAsync();
    }

    public async Task AssignRoleAsync(Guid currentUserId, Guid serverId, Guid targetUserId, Guid roleId)
    {
        var server = await _serversService.AssertPermissionAsync(currentUserId, serverId, ServerPermission.ManageRoles);
        var role = await GetRoleInServerAsync(serverId, roleId);

        if (role.IsDefault)
            throw new CannotModifyDefaultRoleException();

        await _permissionService.AssertCanManageRoleAsync(currentUserId, server, role);
        await _permissionService.AssertCanActOnMemberAsync(currentUserId, targetUserId, server);

        var member = await GetMemberAsync(serverId, targetUserId);

        var alreadyAssigned = await _context.ServerMemberRoles
            .AnyAsync(assignment => assignment.ServerMemberId == member.Id && assignment.RoleId == roleId);

        if (alreadyAssigned)
            return;

        _context.ServerMemberRoles.Add(new ServerMemberRole
        {
            ServerMemberId = member.Id,
            RoleId = roleId
        });

        await _context.SaveChangesAsync();
    }

    public async Task RemoveRoleAsync(Guid currentUserId, Guid serverId, Guid targetUserId, Guid roleId)
    {
        var server = await _serversService.AssertPermissionAsync(currentUserId, serverId, ServerPermission.ManageRoles);
        var role = await GetRoleInServerAsync(serverId, roleId);

        if (role.IsDefault)
            throw new CannotModifyDefaultRoleException();

        await _permissionService.AssertCanManageRoleAsync(currentUserId, server, role);
        await _permissionService.AssertCanActOnMemberAsync(currentUserId, targetUserId, server);

        var member = await GetMemberAsync(serverId, targetUserId);

        var assignment = await _context.ServerMemberRoles
            .FirstOrDefaultAsync(assignment => assignment.ServerMemberId == member.Id && assignment.RoleId == roleId);

        if (assignment is null)
            return;

        _context.ServerMemberRoles.Remove(assignment);

        await _context.SaveChangesAsync();
    }

    public async Task<List<RoleResponse>> GetMemberRolesAsync(Guid currentUserId, Guid serverId, Guid targetUserId)
    {
        await _serversService.AssertServerMemberAsync(currentUserId, serverId);

        var member = await GetMemberAsync(serverId, targetUserId);

        var roles = await _context.ServerMemberRoles
            .Where(assignment => assignment.ServerMemberId == member.Id)
            .Join(_context.Roles, assignment => assignment.RoleId, role => role.Id, (assignment, role) => role)
            .OrderByDescending(role => role.Position)
            .ToListAsync();

        return roles.Select(role => role.MapToResponse()).ToList();
    }

    private async Task<Role> GetRoleInServerAsync(Guid serverId, Guid roleId)
    {
        return await _context.Roles.FirstOrDefaultAsync(role => role.Id == roleId && role.ServerId == serverId)
            ?? throw new RoleNotFoundException();
    }

    private async Task<ServerMember> GetMemberAsync(Guid serverId, Guid userId)
    {
        return await _context.ServerMembers.FirstOrDefaultAsync(member => member.ServerId == serverId && member.UserId == userId)
            ?? throw new TargetNotServerMemberException();
    }

    private async Task AssertCanGrantAsync(Guid currentUserId, Server server, ServerPermission permissions)
    {
        var resolved = await _permissionService.ResolveAsync(currentUserId, server);

        if (resolved.IsOwner)
            return;

        var missing = permissions & ~resolved.Permissions;

        if (missing != ServerPermission.None)
            throw new MissingPermissionException(missing);
    }

    private static ServerPermission ValidatePermissions(long permissions)
    {
        var value = (ServerPermission)permissions;

        if ((value & ~PermissionService.All) != ServerPermission.None)
            throw new ParameterValidationException(nameof(permissions));

        return value;
    }

    private static void ValidateName(string? name)
    {
        if (string.IsNullOrWhiteSpace(name) || name.Length > 100)
            throw new ParameterValidationException(nameof(name));
    }

    private static void ValidateColor(string? color)
    {
        if (!string.IsNullOrWhiteSpace(color) && !HexColorRegex().IsMatch(color))
            throw new ParameterValidationException(nameof(color));
    }
}
