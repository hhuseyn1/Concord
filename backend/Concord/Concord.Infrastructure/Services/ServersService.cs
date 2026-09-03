using System.Security.Cryptography;
using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Application.Realtime;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Extensions;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Services;

public class ServersService(
    ApplicationDbContext context,
    FilesService filesService,
    PermissionService permissionService,
    IServersRealtimeNotifier realtimeNotifier)
{
    private const string InviteCodeAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private const int InviteCodeLength = 8;

    private readonly ApplicationDbContext _context = context;
    private readonly FilesService _filesService = filesService;
    private readonly PermissionService _permissionService = permissionService;
    private readonly IServersRealtimeNotifier _realtimeNotifier = realtimeNotifier;

    public async Task<ServerResponse> CreateServerAsync(Guid currentUserId, CreateServerRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
            throw new ParameterValidationException(nameof(request.Name));

        if (!string.IsNullOrWhiteSpace(request.IconUrl) && !_filesService.IsOwnUploadUrl(request.IconUrl))
            throw new ParameterValidationException(nameof(request.IconUrl));

        var server = new Server
        {
            Name = request.Name,
            OwnerId = currentUserId,
            IconUrl = request.IconUrl
        };

        _context.Servers.Add(server);

        _context.ServerMembers.Add(new ServerMember
        {
            ServerId = server.Id,
            UserId = currentUserId
        });

        // Every server needs its @everyone role from the moment it exists - PermissionService reads
        // it as the baseline for every non-owner, so a server without one would silently grant
        // nothing to its members.
        _context.Roles.Add(RolesService.BuildDefaultRole(server.Id));

        await _context.SaveChangesAsync();

        return server.MapToResponse();
    }

    public async Task<ServerResponse> UpdateServerAsync(Guid currentUserId, Guid serverId, UpdateServerRequest request)
    {
        var server = await AssertPermissionAsync(currentUserId, serverId, ServerPermission.ManageServer);

        if (string.IsNullOrWhiteSpace(request.Name))
            throw new ParameterValidationException(nameof(request.Name));

        if (!string.IsNullOrWhiteSpace(request.IconUrl) && !_filesService.IsOwnUploadUrl(request.IconUrl))
            throw new ParameterValidationException(nameof(request.IconUrl));

        var oldIconUrl = server.IconUrl;

        server.Name = request.Name;
        server.IconUrl = request.IconUrl;

        await _context.SaveChangesAsync();

        if (!string.IsNullOrWhiteSpace(oldIconUrl) && oldIconUrl != request.IconUrl)
            await _filesService.DeleteFileAsync(oldIconUrl);

        var result = server.MapToResponse();

        await _realtimeNotifier.ServerUpdatedAsync(serverId, result);

        return result;
    }

    public async Task<List<ServerSummary>> GetMyServersAsync(Guid currentUserId)
    {
        var servers = await _context.ServerMembers
            .Where(member => member.UserId == currentUserId)
            .Join(_context.Servers,
                member => member.ServerId,
                server => server.Id,
                (member, server) => server)
            .OrderBy(server => server.Created)
            .ToListAsync();

        return servers.Select(server => server.MapToSummary()).ToList();
    }

    public async Task<(ServerResponse Server, bool JoinedNow)> JoinServerAsync(Guid currentUserId, string inviteCode)
    {
        var invite = await _context.Invites
            .FirstOrDefaultAsync(invite => invite.Code == inviteCode);

        if (invite is null ||
            (invite.ExpiresAtUtc.HasValue && invite.ExpiresAtUtc.Value < DateTime.UtcNow) ||
            (invite.MaxUses.HasValue && invite.UseCount >= invite.MaxUses.Value))
            throw new InvalidInviteCodeException();

        var server = await _context.Servers
            .FirstOrDefaultAsync(server => server.Id == invite.ServerId);

        if (server is null)
            throw new ServerNotFoundException();

        // P1: an active ban outranks a valid invite. Queried directly rather than through
        // ModerationService, which depends on this class - going the other way would close a cycle.
        var isBanned = await _context.ServerBans.AnyAsync(ban =>
            ban.ServerId == invite.ServerId &&
            ban.UserId == currentUserId &&
            (ban.ExpiresAtUtc == null || ban.ExpiresAtUtc > DateTime.UtcNow));

        if (isBanned)
            throw new UserBannedException();

        var alreadyMember = await _context.ServerMembers
            .AnyAsync(member => member.ServerId == invite.ServerId && member.UserId == currentUserId);

        if (!alreadyMember)
        {
            _context.ServerMembers.Add(new ServerMember
            {
                ServerId = invite.ServerId,
                UserId = currentUserId
            });

            invite.UseCount++;

            await _context.SaveChangesAsync();
        }

        var result = server.MapToResponse();
        var joinedNow = !alreadyMember;

        if (joinedNow)
            await _realtimeNotifier.ServerMemberJoinedAsync(result.Id, currentUserId);

        return (result, joinedNow);
    }

    public async Task LeaveServerAsync(Guid currentUserId, Guid serverId)
    {
        var server = await AssertServerMemberAsync(currentUserId, serverId);

        if (server.OwnerId == currentUserId)
            throw new CannotLeaveAsOwnerException();

        var member = await _context.ServerMembers
            .FirstOrDefaultAsync(member => member.ServerId == serverId && member.UserId == currentUserId);

        if (member is not null)
        {
            _context.ServerMembers.Remove(member);
            await _context.SaveChangesAsync();
        }

        await _realtimeNotifier.ServerMemberLeftAsync(serverId, currentUserId);
    }

    public async Task RemoveMemberAsync(Guid currentUserId, Guid serverId, Guid targetUserId)
    {
        var server = await AssertPermissionAsync(currentUserId, serverId, ServerPermission.KickMembers);

        // Rejects self-targeting, targeting the owner, and targeting anyone at or above the
        // caller's own rank.
        await _permissionService.AssertCanActOnMemberAsync(currentUserId, targetUserId, server);

        var member = await _context.ServerMembers
            .FirstOrDefaultAsync(member => member.ServerId == serverId && member.UserId == targetUserId);

        if (member is null)
            throw new TargetNotServerMemberException();

        _context.ServerMembers.Remove(member);

        await _context.SaveChangesAsync();

        await _realtimeNotifier.ServerMemberLeftAsync(serverId, targetUserId);
        await _realtimeNotifier.RemovedFromServerAsync(targetUserId, serverId);
    }

    public async Task DeleteServerAsync(Guid currentUserId, Guid serverId)
    {
        var server = await AssertServerOwnerAsync(currentUserId, serverId);

        _context.Servers.Remove(server);

        await _context.SaveChangesAsync();
    }

    public async Task TransferOwnershipAsync(Guid currentUserId, Guid serverId, TransferOwnershipRequest request)
    {
        var server = await AssertServerOwnerAsync(currentUserId, serverId);

        var targetIsMember = await _context.ServerMembers
            .AnyAsync(member => member.ServerId == serverId && member.UserId == request.NewOwnerUserId);

        if (!targetIsMember)
            throw new TargetNotServerMemberException();

        server.OwnerId = request.NewOwnerUserId;

        await _context.SaveChangesAsync();
    }

    public async Task<PagedResult<ServerMemberSummary>> GetMembersAsync(Guid currentUserId, Guid serverId, int page, int pageSize)
    {
        await AssertServerMemberAsync(currentUserId, serverId);

        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        var membersQuery = _context.ServerMembers
            .Where(member => member.ServerId == serverId);

        var totalCount = await membersQuery.CountAsync();

        var members = await membersQuery
            .OrderBy(member => member.Created)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Join(_context.Users,
                member => member.UserId,
                user => user.Id,
                (member, user) => new { Member = member, User = user })
            .ToListAsync();

        var memberUserIds = members.Select(x => x.User.Id).ToList();

        var presencesById = await _context.UserPresences
            .Where(presence => memberUserIds.Contains(presence.UserId))
            .ToDictionaryAsync(presence => presence.UserId);

        var blockedUserIds = await GetBlockedAmongCandidatesAsync(currentUserId, memberUserIds);

        return new PagedResult<ServerMemberSummary>
        {
            Items = members
                .Select(x => x.Member.MapToSummary(
                    x.User,
                    blockedUserIds.Contains(x.User.Id) ? null : presencesById.GetValueOrDefault(x.User.Id)))
                .ToList(),
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    private async Task<HashSet<Guid>> GetBlockedAmongCandidatesAsync(Guid viewerId, List<Guid> candidateUserIds)
    {
        if (candidateUserIds.Count == 0)
            return [];

        var blockedIds = await _context.Blocks
            .Where(block =>
                (block.BlockerId == viewerId && candidateUserIds.Contains(block.BlockedId)) ||
                (block.BlockedId == viewerId && candidateUserIds.Contains(block.BlockerId)))
            .Select(block => block.BlockerId == viewerId ? block.BlockedId : block.BlockerId)
            .ToListAsync();

        return blockedIds.ToHashSet();
    }

    public async Task<List<Guid>> GetFellowMemberUserIdsAsync(Guid currentUserId)
    {
        var serverIds = _context.ServerMembers
            .Where(member => member.UserId == currentUserId)
            .Select(member => member.ServerId);

        return await _context.ServerMembers
            .Where(member => serverIds.Contains(member.ServerId) && member.UserId != currentUserId)
            .Select(member => member.UserId)
            .Distinct()
            .ToListAsync();
    }

    public async Task<InviteResponse> GenerateInviteAsync(Guid currentUserId, Guid serverId, GenerateInviteRequest request)
    {
        await AssertPermissionAsync(currentUserId, serverId, ServerPermission.ManageInvites);

        if (request.MaxUses.HasValue && request.MaxUses.Value <= 0)
            throw new ParameterValidationException(nameof(request.MaxUses));

        if (request.ExpiresAtUtc.HasValue && request.ExpiresAtUtc.Value <= DateTime.UtcNow)
            throw new ParameterValidationException(nameof(request.ExpiresAtUtc));

        var invite = new Invite
        {
            ServerId = serverId,
            Code = RandomNumberGenerator.GetString(InviteCodeAlphabet, InviteCodeLength),
            CreatedByUserId = currentUserId,
            ExpiresAtUtc = request.ExpiresAtUtc,
            MaxUses = request.MaxUses,
            UseCount = 0
        };

        _context.Invites.Add(invite);

        await _context.SaveChangesAsync();

        return invite.MapToResponse();
    }

    public async Task<List<InviteResponse>> ListInvitesAsync(Guid currentUserId, Guid serverId)
    {
        await AssertPermissionAsync(currentUserId, serverId, ServerPermission.ManageInvites);

        var invites = await _context.Invites
            .Where(invite => invite.ServerId == serverId)
            .OrderByDescending(invite => invite.Created)
            .ToListAsync();

        return invites.Select(invite => invite.MapToResponse()).ToList();
    }

    public async Task<Server> AssertServerMemberAsync(Guid currentUserId, Guid serverId)
    {
        var server = await _context.Servers
            .FirstOrDefaultAsync(server => server.Id == serverId);

        if (server is null)
            throw new ServerNotFoundException();

        var isMember = await _context.ServerMembers
            .AnyAsync(member => member.ServerId == serverId && member.UserId == currentUserId);

        if (!isMember)
            throw new NotServerMemberException();

        return server;
    }

    /// <summary>
    /// Reserved for the two actions that stay tied to ownership itself rather than to a permission:
    /// deleting the server and transferring ownership. Everything else goes through
    /// <see cref="AssertPermissionAsync"/>.
    /// </summary>
    internal async Task<Server> AssertServerOwnerAsync(Guid currentUserId, Guid serverId)
    {
        var server = await AssertServerMemberAsync(currentUserId, serverId);

        if (server.OwnerId != currentUserId)
            throw new NotServerOwnerException();

        return server;
    }

    /// <summary>
    /// The RBAC gate every capability check funnels through: confirms membership, then confirms the
    /// resolved permission set covers <paramref name="required"/>. Returns the server so callers
    /// keep the single-round-trip shape the old owner check had.
    /// </summary>
    public async Task<Server> AssertPermissionAsync(Guid currentUserId, Guid serverId, ServerPermission required)
    {
        var server = await AssertServerMemberAsync(currentUserId, serverId);

        await _permissionService.AssertPermissionAsync(currentUserId, server, required);

        return server;
    }
}
