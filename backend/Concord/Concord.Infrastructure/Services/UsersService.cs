using System.Text.RegularExpressions;
using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Extensions;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Services;

public class UsersService(ApplicationDbContext context, FilesService filesService, PresenceService presenceService, FriendsService friendsService)
{
    private readonly ApplicationDbContext _context = context;
    private readonly FilesService _filesService = filesService;
    private readonly PresenceService _presenceService = presenceService;
    private readonly FriendsService _friendsService = friendsService;

    private static Regex UsernameRegex() => new("^[a-zA-Z0-9_]{1,32}$");

    public async Task<MyProfileResponse> GetMyProfileAsync(Guid currentUserId)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(user => user.Id == currentUserId);

        if (user is null)
            throw new UserNotFoundException(currentUserId);

        var presence = await _context.UserPresences.FirstOrDefaultAsync(presence => presence.UserId == currentUserId);

        return user.MapToModel(presence);
    }

    public async Task<MyProfileResponse> UpdateMyProfileAsync(Guid currentUserId, UpdateProfileRequest request)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(user => user.Id == currentUserId);

        if (user is null)
            throw new UserNotFoundException(currentUserId);

        if (string.IsNullOrWhiteSpace(request.Name))
            throw new ParameterValidationException(nameof(request.Name));

        if (string.IsNullOrWhiteSpace(request.Surname))
            throw new ParameterValidationException(nameof(request.Surname));

        if (string.IsNullOrWhiteSpace(request.Username))
            throw new ParameterValidationException(nameof(request.Username));

        if (!UsernameRegex().IsMatch(request.Username))
            throw new ParameterValidationException(nameof(request.Username));

        if (!string.IsNullOrWhiteSpace(request.AvatarUrl) && !_filesService.IsOwnUploadUrl(request.AvatarUrl))
            throw new ParameterValidationException(nameof(request.AvatarUrl));

        await ValidateUsernameUniqueAsync(currentUserId, request.Username);

        var oldAvatarUrl = user.AvatarUrl;

        user.Name = request.Name;
        user.Surname = request.Surname;
        user.Username = request.Username;
        user.AvatarUrl = request.AvatarUrl;

        await _context.SaveChangesAsync();

        if (!string.IsNullOrWhiteSpace(oldAvatarUrl) && oldAvatarUrl != request.AvatarUrl)
            await _filesService.DeleteFileAsync(oldAvatarUrl);

        return await GetMyProfileAsync(currentUserId);
    }

    public async Task<PublicProfileResponse> GetPublicProfileAsync(Guid currentUserId, Guid userId)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(user => user.Id == userId);

        if (user is null || user.Disabled.HasValue)
            throw new UserNotFoundException(userId);

        var canViewPresence = await _presenceService.CanViewPresenceAsync(currentUserId, userId);

        var presence = canViewPresence
            ? await _context.UserPresences.FirstOrDefaultAsync(presence => presence.UserId == userId)
            : null;

        if (userId == currentUserId)
            return user.MapToPublicModel(presence);

        if (await _friendsService.IsBlockedByMeAsync(currentUserId, userId))
            return user.MapToPublicModel(presence, FriendRelationshipStatus.Blocked);

        var friendIds = (await _friendsService.GetFriendUserIdsAsync(currentUserId)).ToHashSet();
        var outgoingRequestIds = await _friendsService.GetOutgoingPendingRequestIdsAsync(currentUserId, [userId]);
        var incomingRequestIds = await _friendsService.GetIncomingPendingRequestIdsAsync(currentUserId, [userId]);
        var (relationshipStatus, pendingRequestId) = ResolveRelationship(userId, friendIds, outgoingRequestIds, incomingRequestIds);

        var mutualFriendsCount = await _friendsService.GetMutualFriendsCountAsync(currentUserId, userId);

        return user.MapToPublicModel(presence, relationshipStatus, pendingRequestId, mutualFriendsCount);
    }

    public async Task<List<PublicProfileResponse>> SearchByUsernameAsync(Guid currentUserId, string query)
    {
        if (string.IsNullOrWhiteSpace(query) || query.Length < 2)
            throw new ParameterValidationException(nameof(query));

        var users = await _context.Users
            .Where(user => !user.Disabled.HasValue &&
                           user.Id != currentUserId &&
                           user.Username != null &&
                           EF.Functions.ILike(user.Username, $"%{query}%"))
            .Take(20)
            .ToListAsync();

        var userIds = users.Select(user => user.Id).ToList();

        var blockedUserIds = await _friendsService.GetBlockedUserIdsAsync(currentUserId, userIds);
        users = users.Where(user => !blockedUserIds.Contains(user.Id)).ToList();
        userIds = users.Select(user => user.Id).ToList();

        var presencesById = await _context.UserPresences
            .Where(presence => userIds.Contains(presence.UserId))
            .ToDictionaryAsync(presence => presence.UserId);

        var viewablePresenceUserIds = await _presenceService.GetViewablePresenceUserIdsAsync(currentUserId, userIds);

        var friendIds = (await _friendsService.GetFriendUserIdsAsync(currentUserId)).ToHashSet();
        var outgoingRequestIds = await _friendsService.GetOutgoingPendingRequestIdsAsync(currentUserId, userIds);
        var incomingRequestIds = await _friendsService.GetIncomingPendingRequestIdsAsync(currentUserId, userIds);

        return users
            .Select(user =>
            {
                var (status, pendingRequestId) = ResolveRelationship(user.Id, friendIds, outgoingRequestIds, incomingRequestIds);

                return user.MapToPublicModel(
                    viewablePresenceUserIds.Contains(user.Id) ? presencesById.GetValueOrDefault(user.Id) : null,
                    status,
                    pendingRequestId);
            })
            .ToList();
    }

    private static (FriendRelationshipStatus Status, Guid? PendingRequestId) ResolveRelationship(
        Guid targetUserId,
        HashSet<Guid> friendIds,
        Dictionary<Guid, Guid> outgoingRequestIds,
        Dictionary<Guid, Guid> incomingRequestIds)
    {
        if (friendIds.Contains(targetUserId))
            return (FriendRelationshipStatus.Friends, null);

        if (incomingRequestIds.TryGetValue(targetUserId, out var incomingRequestId))
            return (FriendRelationshipStatus.IncomingRequest, incomingRequestId);

        if (outgoingRequestIds.TryGetValue(targetUserId, out var outgoingRequestId))
            return (FriendRelationshipStatus.OutgoingRequest, outgoingRequestId);

        return (FriendRelationshipStatus.None, null);
    }

    public async Task<MyProfileResponse> UpdateMyPreferencesAsync(Guid currentUserId, UpdatePreferencesRequest request)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(user => user.Id == currentUserId);

        if (user is null)
            throw new UserNotFoundException(currentUserId);

        if (string.IsNullOrWhiteSpace(request.Locale) || !GlobalConstants.SupportedLocales.Contains(request.Locale))
            throw new ParameterValidationException(nameof(request.Locale));

        user.Locale = request.Locale;
        user.NotificationsMuted = request.NotificationsMuted;
        user.NotificationsSoundEnabled = request.NotificationsSoundEnabled;

        await _context.SaveChangesAsync();

        return await GetMyProfileAsync(currentUserId);
    }

    public async Task<MyProfileResponse> UpdateMyPrivacyAsync(Guid currentUserId, UpdatePrivacyRequest request)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(user => user.Id == currentUserId);

        if (user is null)
            throw new UserNotFoundException(currentUserId);

        user.FriendRequestPrivacy = request.FriendRequestPrivacy;
        user.DirectMessagePrivacy = request.DirectMessagePrivacy;
        user.ActivityVisibility = request.ActivityVisibility;
        user.ReadReceiptsEnabled = request.ReadReceiptsEnabled;

        await _context.SaveChangesAsync();

        return await GetMyProfileAsync(currentUserId);
    }

    public async Task<MyProfileResponse> UpdateMyCustomStatusAsync(Guid currentUserId, UpdateCustomStatusRequest request)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(user => user.Id == currentUserId);

        if (user is null)
            throw new UserNotFoundException(currentUserId);

        if (!string.IsNullOrWhiteSpace(request.Emoji) && request.Emoji.Length > 16)
            throw new ParameterValidationException(nameof(request.Emoji));

        if (!string.IsNullOrWhiteSpace(request.Text) && request.Text.Length > 128)
            throw new ParameterValidationException(nameof(request.Text));

        user.CustomStatusEmoji = string.IsNullOrWhiteSpace(request.Emoji) ? null : request.Emoji;
        user.CustomStatusText = string.IsNullOrWhiteSpace(request.Text) ? null : request.Text;
        user.CustomStatusExpiresAt = string.IsNullOrWhiteSpace(request.Text) ? null : ResolveExpiresAt(request.ExpiryPreset);

        await _context.SaveChangesAsync();

        return await GetMyProfileAsync(currentUserId);
    }

    public async Task<MyProfileResponse> UpdateMyActivityAsync(Guid currentUserId, UpdateActivityRequest request)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(user => user.Id == currentUserId);

        if (user is null)
            throw new UserNotFoundException(currentUserId);

        if (!string.IsNullOrWhiteSpace(request.ApplicationName) && request.ApplicationName.Length > 128)
            throw new ParameterValidationException(nameof(request.ApplicationName));

        if (string.IsNullOrWhiteSpace(request.ApplicationName))
        {
            user.ActivityApplicationName = null;
            user.ActivityType = null;
            user.ActivityStartedAt = null;
        }
        else
        {
            user.ActivityApplicationName = request.ApplicationName;
            user.ActivityType = request.ActivityType;
            user.ActivityStartedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();

        return await GetMyProfileAsync(currentUserId);
    }

    private static DateTime? ResolveExpiresAt(CustomStatusExpiryPreset preset)
    {
        var now = DateTime.UtcNow;

        return preset switch
        {
            CustomStatusExpiryPreset.ThirtyMinutes => now.AddMinutes(30),
            CustomStatusExpiryPreset.OneHour => now.AddHours(1),
            CustomStatusExpiryPreset.FourHours => now.AddHours(4),
            CustomStatusExpiryPreset.Today => now
                .AddHours(GlobalConstants.TimeZoneOffsetHours).Date
                .AddDays(1).AddTicks(-1)
                .AddHours(-GlobalConstants.TimeZoneOffsetHours),
            _ => null
        };
    }

    private async Task ValidateUsernameUniqueAsync(Guid currentUserId, string username)
    {
        var usernameExists = await _context.Users
            .AnyAsync(user => user.Id != currentUserId && user.Username != null && user.Username.ToLower() == username.ToLower());

        if (usernameExists)
            throw new UsernameAlreadyTakenException(username);
    }
}
