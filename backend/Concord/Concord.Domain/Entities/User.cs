using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Domain.Enums;

namespace Concord.Domain.Entities;

public class User : BaseEntity
{
    public User()
    {
        PhoneNumber = null!;
        Email = null!;
        Name = null!;
        Surname = null!;
        Role = Roles.User;
        Locale = GlobalConstants.DefaultLocale;
        NotificationsSoundEnabled = true;
        FriendRequestPrivacy = FriendRequestPrivacy.Everyone;
        DirectMessagePrivacy = DirectMessagePrivacy.FriendsOnly;
        ActivityVisibility = ActivityVisibility.Everyone;
        ReadReceiptsEnabled = true;
        Sessions = [];
    }

    public User(string? email, string? password, string? phoneNumber, string locale, Roles role, string? name, string? surname) : this()
    {
        Name = name;
        Surname = surname;
        Email = email;
        PhoneNumber = phoneNumber;
        Password = password;
        Locale = locale;
        Role = role;
    }

    public Guid Id { get; }

    public string? PhoneNumber { get; set;}

    public string? Email { get; set;}

    public string? Name { get; set; }

    public string? Surname { get; set; }

    public string? Username { get; set; }

    public string? AvatarUrl { get; set; }

    public bool EmailConfirmed { get; set; }

    public bool IsLocked { get; set; }

    public Roles Role { get; set; }

    public string Locale { get; set; }

    public bool NotificationsMuted { get; set; }

    public bool NotificationsSoundEnabled { get; set; }

    public string? CustomStatusEmoji { get; set; }

    public string? CustomStatusText { get; set; }

    public DateTime? CustomStatusExpiresAt { get; set; }

    public FriendRequestPrivacy FriendRequestPrivacy { get; set; }

    public DirectMessagePrivacy DirectMessagePrivacy { get; set; }

    public ActivityVisibility ActivityVisibility { get; set; }

    public bool ReadReceiptsEnabled { get; set; }

    public string? ActivityApplicationName { get; set; }

    public ActivityType? ActivityType { get; set; }

    public DateTime? ActivityStartedAt { get; set; }

    public string? Password { get; set; }

    public string? TwoFactorSecret { get; set; }

    public bool TwoFactorEnabled { get; set; }

    public DateTime? TwoFactorEnabledAt { get; set; }

    public long? TwoFactorLastUsedStep { get; set; }

    public DateTime? Disabled { get; set; }

    public DateTime? DeletionRequestedAt { get; set; }

    public int FailedLoginAttempts { get; set; }

    public DateTime? LockoutEnd { get; set; }

    public int StarsBalance { get; set; }

    public DateTime? PremiumTrialExpiresAt { get; set; }

    public DateTime? LastStarRewardAt { get; set; }

    public int StarsEarnedToday { get; set; }

    public DateOnly? StarsEarnedTodayDate { get; set; }

    public ICollection<Session> Sessions { get; set; }
}
