using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Domain.Entities;
using Concord.Infrastructure.Services;

namespace Concord.Infrastructure.Extensions;

public static class UserExtensions
{
    public static MyProfileResponse MapToModel(this User user, UserPresence? presence = null) => new()
    {
        Id = user.Id,
        Username = user.Username,
        Name = user.Name,
        Surname = user.Surname,
        Email = user.Email,
        Role = user.Role.ToString(),
        PhoneNumber = user.PhoneNumber,
        AvatarUrl = user.AvatarUrl,
        Locale = user.Locale,
        NotificationsMuted = user.NotificationsMuted,
        NotificationsSoundEnabled = user.NotificationsSoundEnabled,
        Status = presence?.Status ?? PresenceStatus.Offline,
        CustomStatusEmoji = user.IsCustomStatusActive() ? user.CustomStatusEmoji : null,
        CustomStatusText = user.IsCustomStatusActive() ? user.CustomStatusText : null,
        CustomStatusExpiresAt = user.IsCustomStatusActive() ? user.CustomStatusExpiresAt : null,
        FriendRequestPrivacy = user.FriendRequestPrivacy,
        DirectMessagePrivacy = user.DirectMessagePrivacy,
        ActivityVisibility = user.ActivityVisibility,
        ReadReceiptsEnabled = user.ReadReceiptsEnabled,
        Created = user.Created,
        ActivityApplicationName = user.ActivityApplicationName,
        ActivityType = user.ActivityType,
        ActivityStartedAt = user.ActivityStartedAt
    };

    public static PublicProfileResponse MapToPublicModel(this User user)
    {
        return user.MapToPublicModel(null);
    }

    public static PublicProfileResponse MapToPublicModel(
        this User user,
        UserPresence? presence,
        FriendRelationshipStatus relationshipStatus = FriendRelationshipStatus.None,
        Guid? pendingRequestId = null,
        int mutualFriendsCount = 0) => new()
    {
        Id = user.Id,
        Username = user.Username,
        Name = user.Name,
        Surname = user.Surname,
        AvatarUrl = user.AvatarUrl,
        Created = user.Created,
        Status = PresenceService.ToVisibleStatus(presence?.Status ?? PresenceStatus.Offline),
        LastSeenAt = presence?.LastSeenAt,
        CustomStatusEmoji = user.IsCustomStatusActive() ? user.CustomStatusEmoji : null,
        CustomStatusText = user.IsCustomStatusActive() ? user.CustomStatusText : null,
        RelationshipStatus = relationshipStatus,
        PendingRequestId = pendingRequestId,
        MutualFriendsCount = mutualFriendsCount,
        ActivityApplicationName = presence is not null ? user.ActivityApplicationName : null,
        ActivityType = presence is not null ? user.ActivityType : null,
        ActivityStartedAt = presence is not null ? user.ActivityStartedAt : null
    };

    private static bool IsCustomStatusActive(this User user) =>
        !string.IsNullOrEmpty(user.CustomStatusText) &&
        (user.CustomStatusExpiresAt is null || user.CustomStatusExpiresAt > DateTime.UtcNow);

    public static AdminUserSummary MapToAdminSummary(this User user) => new()
    {
        Id = user.Id,
        Username = user.Username,
        Name = user.Name,
        Surname = user.Surname,
        Email = user.Email,
        PhoneNumber = user.PhoneNumber,
        AvatarUrl = user.AvatarUrl,
        Role = user.Role.ToString(),
        Disabled = user.Disabled.HasValue,
        TwoFactorEnabled = user.TwoFactorEnabled,
        LockedOut = user.LockoutEnd.HasValue && user.LockoutEnd > DateTime.UtcNow,
        Created = user.Created
    };
}
