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

/// <summary>
/// Ban, mute, and timeout (P1). Kick already exists as
/// <see cref="ServersService.RemoveMemberAsync"/> and is left there rather than duplicated.
///
/// Every action here goes through two gates, in this order: the relevant
/// <see cref="ServerPermission"/>, then <see cref="PermissionService.AssertCanActOnMemberAsync"/>,
/// which is what stops a moderator acting on the owner, on someone who outranks them, or on
/// themselves. Mute and timeout are stored on the member row and subtract from resolved permissions
/// in <see cref="PermissionService.ResolveAsync"/>, so no other service needs to know they exist.
/// </summary>
public class ModerationService(
    ApplicationDbContext context,
    ServersService serversService,
    PermissionService permissionService,
    RoomServiceClient roomServiceClient,
    IServersRealtimeNotifier realtimeNotifier,
    IAuditLogService auditLogService,
    ILogger<ModerationService> logger)
{
    /// <summary>Matches Discord's ceiling; also keeps a typo from producing an effectively permanent timeout.</summary>
    private const int MaxTimeoutMinutes = 28 * 24 * 60;

    private const int MaxReasonLength = 500;

    private readonly ApplicationDbContext _context = context;
    private readonly ServersService _serversService = serversService;
    private readonly PermissionService _permissionService = permissionService;
    private readonly RoomServiceClient _roomServiceClient = roomServiceClient;
    private readonly IServersRealtimeNotifier _realtimeNotifier = realtimeNotifier;
    private readonly IAuditLogService _auditLogService = auditLogService;
    private readonly ILogger<ModerationService> _logger = logger;

    /// <summary>
    /// True while a live ban row exists for this user. Expired bans are treated as absent but are not
    /// deleted here - a read path should not mutate, and the row is still useful history until an
    /// unban or a re-ban replaces it.
    /// </summary>
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
            // A lapsed row is reused rather than rejected - re-banning someone whose temporary ban
            // already expired is a normal action, not a conflict.
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

        // A ban is a kick plus a rejoin block: dropping the membership row keeps every existing
        // membership check correct without teaching them about bans.
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

        // Lapsed bans are filtered out rather than listed as inactive - the list answers "who cannot
        // get back in right now", which is what a moderator is actually asking.
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

        // Revoking Speak only changes the *next* token they mint, so an already-connected participant
        // keeps publishing until this lands on the LiveKit side too.
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

        // A timeout takes Speak as well as SendMessages, so it has to reach a live voice session for
        // the same reason a mute does.
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

        // Only hand Speak back if a mute is not independently holding it down.
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

    /// <summary>
    /// Pushes a publish-permission change into every voice channel of this server where the user is
    /// currently connected. LiveKit is a live system the database cannot reach on its own, so this is
    /// best-effort by design: failures are logged and swallowed, because the durable state is already
    /// committed and the next token mint will enforce it regardless.
    /// </summary>
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
                // Expected whenever they are simply not in this particular room.
                _logger.LogDebug(ex, "Could not update LiveKit permissions for {UserId} in room {Room}", userId, room);
            }
        }
    }

    /// <summary>Drops a banned user out of any voice channel of this server they are still sitting in.</summary>
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

    /// <summary>
    /// The server's voice channels that currently exist as live LiveKit rooms.
    ///
    /// A room only exists while someone is in it, so filtering through <c>ListRooms</c> first turns
    /// "one doomed call per voice channel" into one call plus, almost always, zero or one more - the
    /// difference between 1 and 20+ Twirp round-trips on a server with many voice channels.
    ///
    /// Returns empty on failure: LiveKit being unreachable must not fail a moderation action whose
    /// durable state is already committed and which the next token mint will enforce anyway.
    /// </summary>
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
