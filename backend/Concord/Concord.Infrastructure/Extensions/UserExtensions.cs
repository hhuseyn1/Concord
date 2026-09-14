using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Domain.Entities;
using Concord.Infrastructure.Services;

namespace Concord.Infrastructure.Extensions;

public static class UserExtensions
{
    /// <summary>
    /// Maps to the caller's own full profile. Unlike <see cref="MapToPublicModel"/>, <paramref name="presence"/>'s
    /// <c>Status</c> is reported as-is (real value, e.g. <c>Invisible</c>) - reading your own status is never
    /// projected, since that's exactly what the status picker needs to reflect what you actually chose.
    /// </summary>
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
        // Own view is never gated - see MapToPublicModel's gating for how others see it.
        ActivityApplicationName = user.ActivityApplicationName,
        ActivityType = user.ActivityType,
        ActivityStartedAt = user.ActivityStartedAt
    };

    public static PublicProfileResponse MapToPublicModel(this User user)
    {
        return user.MapToPublicModel(null);
    }

    /// <summary>
    /// Maps to how another user sees this profile. <c>Status</c> is always projected through
    /// <see cref="PresenceService.ToVisibleStatus"/> (Invisible reads as Offline) - <see cref="PublicProfileResponse"/>
    /// is inherently "presence as seen by someone else," never used to read your own status.
    /// </summary>
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
        // Rich presence (P2.8) piggybacks on the same visibility gate every caller already computes
        // for `presence` (PresenceService.CanViewPresenceAsync, which folds in ActivityVisibility) -
        // a non-null `presence` here means that gate passed. This slightly over-hides: a visible
        // target with no UserPresence row yet (never connected) also reads as null here. Accepted
        // rather than threading a separate canViewActivity flag through every call site, since
        // nothing populates these fields yet (P2.8 ships the contract only, no writer exists).
        ActivityApplicationName = presence is not null ? user.ActivityApplicationName : null,
        ActivityType = presence is not null ? user.ActivityType : null,
        ActivityStartedAt = presence is not null ? user.ActivityStartedAt : null
    };

    /// <summary>Expiry is checked at read time rather than cleared by a background job - a lapsed custom status just stops being returned.</summary>
    private static bool IsCustomStatusActive(this User user) =>
        !string.IsNullOrEmpty(user.CustomStatusText) &&
        (user.CustomStatusExpiresAt is null || user.CustomStatusExpiresAt > DateTime.UtcNow);

    /// <summary>Admin-only row shape (P4) - unlike MapToPublicModel this is never shown to another
    /// ordinary user, so it can surface Email, Role, and account-status flags with no gating.</summary>
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
