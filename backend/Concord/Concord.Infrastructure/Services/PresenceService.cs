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

    public async Task<PresenceStatus?> HandleConnectAsync(Guid userId)
    {
        var connectionCount = await _redisDatabase.StringIncrementAsync(GetConnectionCountKey(userId));

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
        var connectionCount = await _redisDatabase.StringDecrementAsync(GetConnectionCountKey(userId));

        if (connectionCount != 0)
            return null;

        var presence = await GetOrCreatePresenceAsync(userId);
        presence.Status = PresenceStatus.Offline;
        presence.LastSeenAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return PresenceStatus.Offline;
    }

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
