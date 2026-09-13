using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Application.Realtime;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Extensions;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Services;

public class FriendsService(
    ApplicationDbContext context,
    NotificationsService notificationsService,
    ServersService serversService,
    INotificationsRealtimeNotifier notificationsRealtimeNotifier)
{
    private readonly ApplicationDbContext _context = context;
    private readonly NotificationsService _notificationsService = notificationsService;
    private readonly ServersService _serversService = serversService;
    private readonly INotificationsRealtimeNotifier _notificationsRealtimeNotifier = notificationsRealtimeNotifier;

    public async Task<SendRequestResponse> SendRequestAsync(Guid currentUserId, Guid targetUserId)
    {
        if (targetUserId == currentUserId)
            throw new CannotTargetSelfException();

        var targetUser = await _context.Users
            .FirstOrDefaultAsync(user => user.Id == targetUserId);

        if (targetUser is null || targetUser.Disabled.HasValue)
            throw new UserNotFoundException(targetUserId);

        await EnsureNotBlockedAsync(currentUserId, targetUserId);

        var crossedRequest = await _context.FriendRequests
            .FirstOrDefaultAsync(request =>
                request.RequesterId == targetUserId &&
                request.AddresseeId == currentUserId &&
                request.Status == FriendRequestStatus.Pending);

        if (crossedRequest is not null)
        {
            crossedRequest.Status = FriendRequestStatus.Accepted;

            await _notificationsService.NotifyFriendRequestAcceptedAsync(crossedRequest.RequesterId, currentUserId);

            await _context.SaveChangesAsync();

            await _notificationsRealtimeNotifier.NotifyAsync(targetUserId, NotificationType.FriendRequestAccepted, currentUserId, reason: null);

            return new SendRequestResponse
            {
                RequestId = crossedRequest.Id,
                Status = FriendRequestStatus.Accepted
            };
        }

        var existingRequest = await _context.FriendRequests
            .AnyAsync(request =>
                (request.RequesterId == currentUserId && request.AddresseeId == targetUserId) ||
                (request.RequesterId == targetUserId && request.AddresseeId == currentUserId));

        if (existingRequest)
            throw new FriendRequestAlreadyExistsException();

        await EnsureFriendRequestAllowedAsync(currentUserId, targetUser);

        var newRequest = new FriendRequest
        {
            RequesterId = currentUserId,
            AddresseeId = targetUserId,
            Status = FriendRequestStatus.Pending
        };

        _context.FriendRequests.Add(newRequest);

        await _notificationsService.NotifyFriendRequestReceivedAsync(targetUserId, currentUserId);

        await _context.SaveChangesAsync();

        await _notificationsRealtimeNotifier.NotifyAsync(targetUserId, NotificationType.FriendRequestReceived, currentUserId, reason: null);

        return new SendRequestResponse
        {
            RequestId = newRequest.Id,
            Status = FriendRequestStatus.Pending
        };
    }

    public async Task<Guid> AcceptRequestAsync(Guid currentUserId, Guid requestId)
    {
        var request = await GetPendingRequestForAddresseeAsync(currentUserId, requestId);

        request.Status = FriendRequestStatus.Accepted;

        await _notificationsService.NotifyFriendRequestAcceptedAsync(request.RequesterId, currentUserId);

        await _context.SaveChangesAsync();

        await _notificationsRealtimeNotifier.NotifyAsync(request.RequesterId, NotificationType.FriendRequestAccepted, currentUserId, reason: null);

        return request.RequesterId;
    }

    public async Task DeclineRequestAsync(Guid currentUserId, Guid requestId)
    {
        var request = await GetPendingRequestForAddresseeAsync(currentUserId, requestId);
        var requesterId = request.RequesterId;

        _context.FriendRequests.Remove(request);

        await _context.SaveChangesAsync();

        // Not persisted as a Notification row (no NotifyFriendRequestDeclinedAsync call) - purely an
        // ephemeral live-update signal so the requester's Outgoing tab stops showing a request that no
        // longer exists, same client-side handling as FriendRequestReceived/Accepted.
        await _notificationsRealtimeNotifier.NotifyAsync(requesterId, NotificationType.FriendRequestDeclined, currentUserId, reason: null);
    }

    public async Task CancelRequestAsync(Guid currentUserId, Guid requestId)
    {
        var request = await _context.FriendRequests
            .FirstOrDefaultAsync(request => request.Id == requestId);

        if (request is null || request.RequesterId != currentUserId || request.Status != FriendRequestStatus.Pending)
            throw new FriendRequestNotFoundException();

        var addresseeId = request.AddresseeId;

        _context.FriendRequests.Remove(request);

        await _context.SaveChangesAsync();

        // Ephemeral only, same rationale as DeclineRequestAsync above - lets the addressee's Incoming
        // tab stop showing a request that's just been withdrawn.
        await _notificationsRealtimeNotifier.NotifyAsync(addresseeId, NotificationType.FriendRequestCancelled, currentUserId, reason: null);
    }

    public async Task BlockUserAsync(Guid currentUserId, Guid targetUserId)
    {
        if (targetUserId == currentUserId)
            throw new CannotTargetSelfException();

        var targetUser = await _context.Users
            .FirstOrDefaultAsync(user => user.Id == targetUserId);

        if (targetUser is null || targetUser.Disabled.HasValue)
            throw new UserNotFoundException(targetUserId);

        var alreadyBlocked = await _context.Blocks
            .AnyAsync(block => block.BlockerId == currentUserId && block.BlockedId == targetUserId);

        if (alreadyBlocked)
            throw new UserAlreadyBlockedException();

        await _context.FriendRequests
            .Where(request =>
                (request.RequesterId == currentUserId && request.AddresseeId == targetUserId) ||
                (request.RequesterId == targetUserId && request.AddresseeId == currentUserId))
            .ExecuteDeleteAsync();

        var block = new Block
        {
            BlockerId = currentUserId,
            BlockedId = targetUserId
        };

        _context.Blocks.Add(block);

        await _context.SaveChangesAsync();
    }

    public async Task UnblockUserAsync(Guid currentUserId, Guid targetUserId)
    {
        var block = await _context.Blocks
            .FirstOrDefaultAsync(block => block.BlockerId == currentUserId && block.BlockedId == targetUserId);

        if (block is null)
            throw new BlockNotFoundException();

        _context.Blocks.Remove(block);

        await _context.SaveChangesAsync();
    }

    public async Task<List<FriendRequestSummary>> GetIncomingRequestsAsync(Guid currentUserId)
    {
        var requests = await _context.FriendRequests
            .Where(request => request.AddresseeId == currentUserId && request.Status == FriendRequestStatus.Pending)
            .Join(_context.Users,
                request => request.RequesterId,
                user => user.Id,
                (request, user) => new { Request = request, OtherUser = user })
            .ToListAsync();

        var otherUserIds = requests.Select(x => x.OtherUser.Id).ToList();

        var presencesById = await _context.UserPresences
            .Where(presence => otherUserIds.Contains(presence.UserId))
            .ToDictionaryAsync(presence => presence.UserId);

        return requests.Select(x => x.Request.MapToSummary(x.OtherUser, presencesById.GetValueOrDefault(x.OtherUser.Id))).ToList();
    }

    public async Task<List<FriendRequestSummary>> GetOutgoingRequestsAsync(Guid currentUserId)
    {
        var requests = await _context.FriendRequests
            .Where(request => request.RequesterId == currentUserId && request.Status == FriendRequestStatus.Pending)
            .Join(_context.Users,
                request => request.AddresseeId,
                user => user.Id,
                (request, user) => new { Request = request, OtherUser = user })
            .ToListAsync();

        var otherUserIds = requests.Select(x => x.OtherUser.Id).ToList();

        var presencesById = await _context.UserPresences
            .Where(presence => otherUserIds.Contains(presence.UserId))
            .ToDictionaryAsync(presence => presence.UserId);

        var viewableUserIds = await GetViewableAmongCandidatesAsync(currentUserId, otherUserIds);

        return requests
            .Select(x => x.Request.MapToSummary(
                x.OtherUser,
                viewableUserIds.Contains(x.OtherUser.Id) ? presencesById.GetValueOrDefault(x.OtherUser.Id) : null))
            .ToList();
    }

    private async Task<HashSet<Guid>> GetViewableAmongCandidatesAsync(Guid viewerId, List<Guid> candidateUserIds)
    {
        if (candidateUserIds.Count == 0)
            return [];

        var friendIds = await GetFriendUserIdsAsync(viewerId);
        var fellowMemberIds = await _serversService.GetFellowMemberUserIdsAsync(viewerId);
        var blockedIds = await GetBlockedUserIdsAsync(viewerId, candidateUserIds);

        var relatedIds = friendIds.Concat(fellowMemberIds).ToHashSet();

        return candidateUserIds.Where(id => relatedIds.Contains(id) && !blockedIds.Contains(id)).ToHashSet();
    }

    public async Task<PagedResult<PublicProfileResponse>> GetFriendsListAsync(Guid currentUserId, int page, int pageSize)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        var friendshipsQuery = _context.FriendRequests
            .Where(request => request.Status == FriendRequestStatus.Accepted &&
                               (request.RequesterId == currentUserId || request.AddresseeId == currentUserId));

        var totalCount = await friendshipsQuery.CountAsync();

        var otherUserIds = await friendshipsQuery
            .OrderBy(request => request.Created)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(request => request.RequesterId == currentUserId ? request.AddresseeId : request.RequesterId)
            .ToListAsync();

        var usersById = await _context.Users
            .Where(user => otherUserIds.Contains(user.Id))
            .ToDictionaryAsync(user => user.Id);

        var presencesById = await _context.UserPresences
            .Where(presence => otherUserIds.Contains(presence.UserId))
            .ToDictionaryAsync(presence => presence.UserId);

        var items = otherUserIds
            .Where(id => usersById.ContainsKey(id))
            .Select(id => usersById[id].MapToPublicModel(presencesById.GetValueOrDefault(id)))
            .ToList();

        return new PagedResult<PublicProfileResponse>
        {
            Items = items,
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    public async Task<List<Guid>> GetFriendUserIdsAsync(Guid currentUserId)
    {
        return await _context.FriendRequests
            .Where(request => request.Status == FriendRequestStatus.Accepted &&
                               (request.RequesterId == currentUserId || request.AddresseeId == currentUserId))
            .Select(request => request.RequesterId == currentUserId ? request.AddresseeId : request.RequesterId)
            .ToListAsync();
    }

    public async Task<bool> AreFriendsAsync(Guid userIdA, Guid userIdB)
    {
        return await _context.FriendRequests
            .AnyAsync(request =>
                request.Status == FriendRequestStatus.Accepted &&
                ((request.RequesterId == userIdA && request.AddresseeId == userIdB) ||
                 (request.RequesterId == userIdB && request.AddresseeId == userIdA)));
    }

    public async Task<bool> IsBlockedByMeAsync(Guid viewerId, Guid targetUserId)
    {
        return await _context.Blocks
            .AnyAsync(block => block.BlockerId == viewerId && block.BlockedId == targetUserId);
    }

    public async Task<bool> AreBlockedAsync(Guid userIdA, Guid userIdB)
    {
        return await _context.Blocks
            .AnyAsync(block =>
                (block.BlockerId == userIdA && block.BlockedId == userIdB) ||
                (block.BlockerId == userIdB && block.BlockedId == userIdA));
    }

    public async Task<Dictionary<Guid, Guid>> GetOutgoingPendingRequestIdsAsync(Guid currentUserId, IEnumerable<Guid> candidateUserIds)
    {
        var candidateIds = candidateUserIds as ICollection<Guid> ?? candidateUserIds.ToList();

        if (candidateIds.Count == 0)
            return [];

        return await _context.FriendRequests
            .Where(request => request.RequesterId == currentUserId &&
                               request.Status == FriendRequestStatus.Pending &&
                               candidateIds.Contains(request.AddresseeId))
            .ToDictionaryAsync(request => request.AddresseeId, request => request.Id);
    }

    public async Task<Dictionary<Guid, Guid>> GetIncomingPendingRequestIdsAsync(Guid currentUserId, IEnumerable<Guid> candidateUserIds)
    {
        var candidateIds = candidateUserIds as ICollection<Guid> ?? candidateUserIds.ToList();

        if (candidateIds.Count == 0)
            return [];

        return await _context.FriendRequests
            .Where(request => request.AddresseeId == currentUserId &&
                               request.Status == FriendRequestStatus.Pending &&
                               candidateIds.Contains(request.RequesterId))
            .ToDictionaryAsync(request => request.RequesterId, request => request.Id);
    }

    public async Task<HashSet<Guid>> GetBlockedUserIdsAsync(Guid viewerId, IEnumerable<Guid> candidateUserIds)
    {
        var candidateIds = candidateUserIds as ICollection<Guid> ?? candidateUserIds.ToList();

        if (candidateIds.Count == 0)
            return [];

        var blockedIds = await _context.Blocks
            .Where(block =>
                (block.BlockerId == viewerId && candidateIds.Contains(block.BlockedId)) ||
                (block.BlockedId == viewerId && candidateIds.Contains(block.BlockerId)))
            .Select(block => block.BlockerId == viewerId ? block.BlockedId : block.BlockerId)
            .ToListAsync();

        return blockedIds.ToHashSet();
    }

    private async Task EnsureNotBlockedAsync(Guid currentUserId, Guid targetUserId)
    {
        if (await AreBlockedAsync(currentUserId, targetUserId))
            throw new UserBlockedException();
    }

    private async Task EnsureFriendRequestAllowedAsync(Guid currentUserId, User targetUser)
    {
        if (targetUser.FriendRequestPrivacy == FriendRequestPrivacy.Nobody)
            throw new FriendRequestsDisabledException();

        if (targetUser.FriendRequestPrivacy == FriendRequestPrivacy.FriendsOfFriends)
        {
            var mutualCount = await GetMutualFriendsCountAsync(currentUserId, targetUser.Id);
            if (mutualCount == 0)
                throw new FriendRequestsDisabledException();
        }
    }

    public async Task<bool> CanDirectMessageAsync(Guid requesterId, User targetUser)
    {
        return targetUser.DirectMessagePrivacy switch
        {
            DirectMessagePrivacy.Nobody => false,
            DirectMessagePrivacy.Everyone => true,
            _ => await AreFriendsAsync(requesterId, targetUser.Id)
        };
    }

    public async Task<int> GetMutualFriendsCountAsync(Guid userIdA, Guid userIdB)
    {
        var friendIdsA = await GetFriendUserIdsAsync(userIdA);
        if (friendIdsA.Count == 0)
            return 0;

        var friendIdsB = (await GetFriendUserIdsAsync(userIdB)).ToHashSet();

        return friendIdsA.Count(id => friendIdsB.Contains(id));
    }

    public async Task<PagedResult<PublicProfileResponse>> GetBlockedListAsync(Guid currentUserId, int page, int pageSize)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        var blocksQuery = _context.Blocks.Where(block => block.BlockerId == currentUserId);

        var totalCount = await blocksQuery.CountAsync();

        var blockedUserIds = await blocksQuery
            .OrderBy(block => block.Created)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(block => block.BlockedId)
            .ToListAsync();

        var usersById = await _context.Users
            .Where(user => blockedUserIds.Contains(user.Id))
            .ToDictionaryAsync(user => user.Id);

        var items = blockedUserIds
            .Where(id => usersById.ContainsKey(id))
            .Select(id => usersById[id].MapToPublicModel())
            .ToList();

        return new PagedResult<PublicProfileResponse>
        {
            Items = items,
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    private async Task<FriendRequest> GetPendingRequestForAddresseeAsync(Guid currentUserId, Guid requestId)
    {
        var request = await _context.FriendRequests
            .FirstOrDefaultAsync(request => request.Id == requestId);

        if (request is null || request.AddresseeId != currentUserId || request.Status != FriendRequestStatus.Pending)
            throw new FriendRequestNotFoundException();

        return request;
    }
}
