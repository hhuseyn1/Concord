using Concord.Application.Enums;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;
using StackExchange.Redis;

namespace Concord.Infrastructure.Services;

public class PresenceService(ApplicationDbContext context, IDatabase redisDatabase, FriendsService friendsService, ServersService serversService)
{
    private readonly ApplicationDbContext _context = context;
    private readonly IDatabase _redisDatabase = redisDatabase;
    private readonly FriendsService _friendsService = friendsService;
    private readonly ServersService _serversService = serversService;

    /// <summary>
    /// TTL for the connection-count key below. Without one, a server process that dies without
    /// running <see cref="HandleDisconnectAsync"/> for its connections (e.g. an OOM-kill) leaves
    /// the counter stuck above zero forever, and the affected users would appear permanently
    /// "online". The TTL bounds that window instead; <see cref="RenewConnectionAsync"/> keeps
    /// renewing it for as long as the connection is actually still alive.
    /// </summary>
    private static readonly TimeSpan ConnectionCountTtl = TimeSpan.FromMinutes(3);

    public async Task<PresenceStatus?> HandleConnectAsync(Guid userId)
    {
        var key = GetConnectionCountKey(userId);
        var connectionCount = await _redisDatabase.StringIncrementAsync(key);
        await _redisDatabase.KeyExpireAsync(key, ConnectionCountTtl);

        if (connectionCount != 1)
            return null;

        var presence = await GetOrCreatePresenceAsync(userId);

        if (presence.Status == PresenceStatus.Offline)
            presence.Status = PresenceStatus.Online;

        await _context.SaveChangesAsync();

        return presence.Status;
    }

    public async Task<PresenceStatus?> HandleDisconnectAsync(Guid userId)
    {
        var key = GetConnectionCountKey(userId);
        var connectionCount = await _redisDatabase.StringDecrementAsync(key);

        // <= 0 rather than == 0 so a key that already expired and got decremented into negative
        // territory (the crash scenario this TTL exists for) is cleaned up rather than left
        // dangling at -1, -2, etc. for the next connect to have to climb back out of.
        if (connectionCount <= 0)
            await _redisDatabase.KeyDeleteAsync(key);
        else
            await _redisDatabase.KeyExpireAsync(key, ConnectionCountTtl);

        if (connectionCount != 0)
            return null;

        var presence = await GetOrCreatePresenceAsync(userId);
        presence.Status = PresenceStatus.Offline;
        presence.LastSeenAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return PresenceStatus.Offline;
    }

    /// <summary>
    /// Refreshes the connection-count key's TTL so a still-healthy, long-lived connection never
    /// hits it - called periodically by a PresenceHub client heartbeat. A no-op if the key has
    /// already expired (EXPIRE on a missing key does nothing): that means this connection's
    /// heartbeats lagged past the TTL, and resurrecting a phantom counter would be worse than
    /// letting the next real connect/disconnect re-establish it correctly.
    /// </summary>
    public Task RenewConnectionAsync(Guid userId) =>
        _redisDatabase.KeyExpireAsync(GetConnectionCountKey(userId), ConnectionCountTtl);

    public async Task SetStatusAsync(Guid userId, PresenceStatus status)
    {
        if (status == PresenceStatus.Offline)
            throw new ParameterValidationException(nameof(status));

        var presence = await GetOrCreatePresenceAsync(userId);
        presence.Status = status;

        await _context.SaveChangesAsync();
    }

    public static PresenceStatus ToVisibleStatus(PresenceStatus status) =>
        status == PresenceStatus.Invisible ? PresenceStatus.Offline : status;

    public async Task<List<Guid>> GetAudienceAsync(Guid userId)
    {
        var friendIds = await _friendsService.GetFriendUserIdsAsync(userId);
        var fellowMemberIds = await _serversService.GetFellowMemberUserIdsAsync(userId);

        var candidates = friendIds
            .Concat(fellowMemberIds)
            .Where(id => id != userId)
            .Distinct()
            .ToList();

        var blockedIds = await _friendsService.GetBlockedUserIdsAsync(userId, candidates);

        return candidates.Where(id => !blockedIds.Contains(id)).ToList();
    }

    public async Task<bool> CanViewPresenceAsync(Guid viewerId, Guid targetUserId)
    {
        if (viewerId == targetUserId)
            return true;

        if (await _friendsService.AreBlockedAsync(viewerId, targetUserId))
            return false;

        var audience = await GetAudienceAsync(viewerId);

        if (!audience.Contains(targetUserId))
            return false;

        var targetVisibility = await _context.Users
            .Where(user => user.Id == targetUserId)
            .Select(user => user.ActivityVisibility)
            .FirstOrDefaultAsync();

        return await PassesActivityVisibilityAsync(viewerId, targetUserId, targetVisibility);
    }

    public async Task<HashSet<Guid>> GetViewablePresenceUserIdsAsync(Guid viewerId, IEnumerable<Guid> candidateUserIds)
    {
        var candidateIds = candidateUserIds as ICollection<Guid> ?? candidateUserIds.ToList();

        if (candidateIds.Count == 0)
            return [];

        var audience = await GetAudienceAsync(viewerId);
        var audienceSet = audience.ToHashSet();

        var relevantCandidates = candidateIds.Where(id => audienceSet.Contains(id) || id == viewerId).ToList();

        var blockedIds = await _friendsService.GetBlockedUserIdsAsync(viewerId, relevantCandidates);
        var stillRelevant = relevantCandidates.Where(id => !blockedIds.Contains(id)).ToList();

        var visibilityById = await _context.Users
            .Where(user => stillRelevant.Contains(user.Id))
            .Select(user => new { user.Id, user.ActivityVisibility })
            .ToDictionaryAsync(user => user.Id, user => user.ActivityVisibility);

        var friendIds = (await _friendsService.GetFriendUserIdsAsync(viewerId)).ToHashSet();

        return stillRelevant
            .Where(id => id == viewerId || visibilityById.GetValueOrDefault(id) switch
            {
                ActivityVisibility.Nobody => false,
                ActivityVisibility.FriendsOnly => friendIds.Contains(id),
                _ => true
            })
            .ToHashSet();
    }

    private async Task<bool> PassesActivityVisibilityAsync(Guid viewerId, Guid targetUserId, ActivityVisibility targetVisibility) => targetVisibility switch
    {
        ActivityVisibility.Nobody => false,
        ActivityVisibility.FriendsOnly => await _friendsService.AreFriendsAsync(viewerId, targetUserId),
        _ => true
    };

    private async Task<UserPresence> GetOrCreatePresenceAsync(Guid userId)
    {
        var presence = await _context.UserPresences
            .FirstOrDefaultAsync(presence => presence.UserId == userId);

        if (presence is null)
        {
            presence = new UserPresence { UserId = userId };
            _context.UserPresences.Add(presence);
        }

        return presence;
    }

    private static string GetConnectionCountKey(Guid userId) => $"presence:conn-count:{userId}";
}
