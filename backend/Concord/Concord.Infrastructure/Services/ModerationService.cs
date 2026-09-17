using Concord.Application.Auditing;
using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Application.Realtime;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Extensions;
using Livekit.Server.Sdk.Dotnet;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Concord.Infrastructure.Services;

public class ModerationService(
    ApplicationDbContext context,
    ServersService serversService,
    PermissionService permissionService,
    RoomServiceClient roomServiceClient,
    IServersRealtimeNotifier realtimeNotifier,
    IAuditLogService auditLogService,
    ILogger<ModerationService> logger)
{
    private const int MaxTimeoutMinutes = 28 * 24 * 60;

    private const int MaxReasonLength = 500;

    private readonly ApplicationDbContext _context = context;
    private readonly ServersService _serversService = serversService;
    private readonly PermissionService _permissionService = permissionService;
    private readonly RoomServiceClient _roomServiceClient = roomServiceClient;
    private readonly IServersRealtimeNotifier _realtimeNotifier = realtimeNotifier;
    private readonly IAuditLogService _auditLogService = auditLogService;
    private readonly ILogger<ModerationService> _logger = logger;

    public async Task<bool> IsBannedAsync(Guid serverId, Guid userId)
    {
        return await _context.ServerBans.AnyAsync(ban =>
            ban.ServerId == serverId &&
            ban.UserId == userId &&
            (ban.ExpiresAtUtc == null || ban.ExpiresAtUtc > DateTime.UtcNow));
    }

    public async Task BanMemberAsync(Guid currentUserId, Guid serverId, Guid targetUserId, BanMemberRequest request)
    {
        var server = await _serversService.AssertPermissionAsync(currentUserId, serverId, ServerPermission.BanMembers);

        await _permissionService.AssertCanActOnMemberAsync(currentUserId, targetUserId, server);

        ValidateReason(request.Reason);

        if (request.ExpiresAtUtc.HasValue && request.ExpiresAtUtc.Value <= DateTime.UtcNow)
            throw new ParameterValidationException(nameof(request.ExpiresAtUtc));

        var existingBan = await _context.ServerBans
            .FirstOrDefaultAsync(ban => ban.ServerId == serverId && ban.UserId == targetUserId);

        if (existingBan is not null)
        {
            var stillActive = existingBan.ExpiresAtUtc is null || existingBan.ExpiresAtUtc > DateTime.UtcNow;

            if (stillActive)
                throw new AlreadyBannedException();

            existingBan.BannedByUserId = currentUserId;
            existingBan.Reason = request.Reason;
            existingBan.ExpiresAtUtc = request.ExpiresAtUtc;
            existingBan.Created = DateTime.UtcNow;
        }
        else
        {
            _context.ServerBans.Add(new ServerBan
            {
                ServerId = serverId,
                UserId = targetUserId,
                BannedByUserId = currentUserId,
                Reason = request.Reason,
                ExpiresAtUtc = request.ExpiresAtUtc
            });
        }

        var member = await _context.ServerMembers
            .FirstOrDefaultAsync(member => member.ServerId == serverId && member.UserId == targetUserId);

        if (member is not null)
            _context.ServerMembers.Remove(member);

        await _context.SaveChangesAsync();

        await DisconnectFromServerVoiceAsync(serverId, targetUserId);

        await _realtimeNotifier.ServerMemberLeftAsync(serverId, targetUserId);
        await _realtimeNotifier.RemovedFromServerAsync(targetUserId, serverId);

        _logger.LogInformation("User {TargetUserId} banned from server {ServerId} by {ActorUserId}",
            targetUserId, serverId, currentUserId);

        await _auditLogService.LogAsync(currentUserId, "MemberBanned", nameof(Server), serverId,
            System.Text.Json.JsonSerializer.Serialize(new { TargetUserId = targetUserId, request.Reason }));
    }

    public async Task UnbanUserAsync(Guid currentUserId, Guid serverId, Guid targetUserId)
    {
        await _serversService.AssertPermissionAsync(currentUserId, serverId, ServerPermission.BanMembers);

        var ban = await _context.ServerBans
            .FirstOrDefaultAsync(ban => ban.ServerId == serverId && ban.UserId == targetUserId)
            ?? throw new BanNotFoundException();

        _context.ServerBans.Remove(ban);

        await _context.SaveChangesAsync();

        _logger.LogInformation("Ban on user {TargetUserId} in server {ServerId} lifted by {ActorUserId}",
            targetUserId, serverId, currentUserId);

        await _auditLogService.LogAsync(currentUserId, "MemberUnbanned", nameof(Server), serverId,
            System.Text.Json.JsonSerializer.Serialize(new { TargetUserId = targetUserId }));
    }

    public async Task<PagedResult<ServerBanResponse>> GetBansAsync(Guid currentUserId, Guid serverId, int page, int pageSize)
    {
        await _serversService.AssertPermissionAsync(currentUserId, serverId, ServerPermission.BanMembers);

        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        var bansQuery = _context.ServerBans
            .Where(ban => ban.ServerId == serverId && (ban.ExpiresAtUtc == null || ban.ExpiresAtUtc > DateTime.UtcNow));

        var totalCount = await bansQuery.CountAsync();

        var bans = await bansQuery
            .OrderByDescending(ban => ban.Created)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Join(_context.Users, ban => ban.UserId, user => user.Id, (ban, user) => new { Ban = ban, User = user })
            .ToListAsync();

        return new PagedResult<ServerBanResponse>
        {
            Items = bans.Select(entry => entry.Ban.MapToResponse(entry.User)).ToList(),
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    public async Task<MemberModerationResponse> SetMuteAsync(Guid currentUserId, Guid serverId, Guid targetUserId, bool muted)
    {
        var server = await _serversService.AssertPermissionAsync(currentUserId, serverId, ServerPermission.MuteMembers);

        await _permissionService.AssertCanActOnMemberAsync(currentUserId, targetUserId, server);

        var member = await GetMemberAsync(serverId, targetUserId);

        member.IsMuted = muted;

        await _context.SaveChangesAsync();

        await ApplyVoicePublishPermissionAsync(serverId, targetUserId, canPublish: !muted);

        await _realtimeNotifier.ServerModerationChangedAsync(serverId, targetUserId);

        _logger.LogInformation("User {TargetUserId} {Action} in server {ServerId} by {ActorUserId}",
            targetUserId, muted ? "muted" : "unmuted", serverId, currentUserId);

        await _auditLogService.LogAsync(currentUserId, muted ? "MemberMuted" : "MemberUnmuted", nameof(Server), serverId,
            System.Text.Json.JsonSerializer.Serialize(new { TargetUserId = targetUserId }));

        return member.MapToModerationResponse();
    }

    public async Task<MemberModerationResponse> TimeoutMemberAsync(
        Guid currentUserId, Guid serverId, Guid targetUserId, TimeoutMemberRequest request)
    {
        var server = await _serversService.AssertPermissionAsync(currentUserId, serverId, ServerPermission.ModerateMembers);

        await _permissionService.AssertCanActOnMemberAsync(currentUserId, targetUserId, server);

        if (request.DurationMinutes <= 0 || request.DurationMinutes > MaxTimeoutMinutes)
            throw new ParameterValidationException(nameof(request.DurationMinutes));

        ValidateReason(request.Reason);

        var member = await GetMemberAsync(serverId, targetUserId);

        member.TimedOutUntil = DateTime.UtcNow.AddMinutes(request.DurationMinutes);
        member.TimedOutByUserId = currentUserId;
        member.TimeoutReason = request.Reason;

        await _context.SaveChangesAsync();

        await ApplyVoicePublishPermissionAsync(serverId, targetUserId, canPublish: false);

        await _realtimeNotifier.ServerModerationChangedAsync(serverId, targetUserId);

        _logger.LogInformation("User {TargetUserId} timed out until {Until} in server {ServerId} by {ActorUserId}",
            targetUserId, member.TimedOutUntil, serverId, currentUserId);

        await _auditLogService.LogAsync(currentUserId, "MemberTimedOut", nameof(Server), serverId,
            System.Text.Json.JsonSerializer.Serialize(new { TargetUserId = targetUserId, member.TimedOutUntil, request.Reason }));

        return member.MapToModerationResponse();
    }

    public async Task<MemberModerationResponse> RemoveTimeoutAsync(Guid currentUserId, Guid serverId, Guid targetUserId)
    {
        var server = await _serversService.AssertPermissionAsync(currentUserId, serverId, ServerPermission.ModerateMembers);

        await _permissionService.AssertCanActOnMemberAsync(currentUserId, targetUserId, server);

        var member = await GetMemberAsync(serverId, targetUserId);

        member.TimedOutUntil = null;
        member.TimedOutByUserId = null;
        member.TimeoutReason = null;

        await _context.SaveChangesAsync();

        await ApplyVoicePublishPermissionAsync(serverId, targetUserId, canPublish: !member.IsMuted);

        await _realtimeNotifier.ServerModerationChangedAsync(serverId, targetUserId);

        _logger.LogInformation("Timeout on user {TargetUserId} in server {ServerId} lifted by {ActorUserId}",
            targetUserId, serverId, currentUserId);

        await _auditLogService.LogAsync(currentUserId, "MemberTimeoutRemoved", nameof(Server), serverId,
            System.Text.Json.JsonSerializer.Serialize(new { TargetUserId = targetUserId }));

        return member.MapToModerationResponse();
    }

    public async Task<MemberModerationResponse> GetMemberModerationAsync(Guid currentUserId, Guid serverId, Guid targetUserId)
    {
        await _serversService.AssertServerMemberAsync(currentUserId, serverId);

        var member = await GetMemberAsync(serverId, targetUserId);

        return member.MapToModerationResponse();
    }

    private async Task<ServerMember> GetMemberAsync(Guid serverId, Guid userId)
    {
        return await _context.ServerMembers.FirstOrDefaultAsync(member => member.ServerId == serverId && member.UserId == userId)
            ?? throw new TargetNotServerMemberException();
    }

    private async Task ApplyVoicePublishPermissionAsync(Guid serverId, Guid userId, bool canPublish)
    {
        foreach (var room in await GetLiveVoiceRoomsAsync(serverId))
        {
            try
            {
                await _roomServiceClient.UpdateParticipant(new UpdateParticipantRequest
                {
                    Room = room,
                    Identity = userId.ToString(),
                    Permission = new ParticipantPermission
                    {
                        CanSubscribe = true,
                        CanPublish = canPublish,
                        CanPublishData = canPublish
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogDebug(ex, "Could not update LiveKit permissions for {UserId} in room {Room}", userId, room);
            }
        }
    }

    private async Task DisconnectFromServerVoiceAsync(Guid serverId, Guid userId)
    {
        foreach (var room in await GetLiveVoiceRoomsAsync(serverId))
        {
            try
            {
                await _roomServiceClient.RemoveParticipant(new RoomParticipantIdentity
                {
                    Room = room,
                    Identity = userId.ToString()
                });
            }
            catch (Exception ex)
            {
                _logger.LogDebug(ex, "Could not remove {UserId} from LiveKit room {Room}", userId, room);
            }
        }
    }

    private async Task<List<string>> GetLiveVoiceRoomsAsync(Guid serverId)
    {
        var voiceChannelIds = await _context.Channels
            .Where(channel => channel.ServerId == serverId && channel.Type == ChannelType.Voice)
            .Select(channel => channel.Id)
            .ToListAsync();

        if (voiceChannelIds.Count == 0)
            return [];

        var request = new ListRoomsRequest();
        request.Names.AddRange(voiceChannelIds.Select(id => id.ToString()));

        try
        {
            var response = await _roomServiceClient.ListRooms(request);

            return response.Rooms.Select(room => room.Name).ToList();
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not list LiveKit rooms for server {ServerId}; skipping live voice enforcement", serverId);

            return [];
        }
    }

    private static void ValidateReason(string? reason)
    {
        if (!string.IsNullOrEmpty(reason) && reason.Length > MaxReasonLength)
            throw new ParameterValidationException(nameof(reason));
    }
}
