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

    /// <summary>Rich presence (P2.8), reported by a future Desktop Presence Agent - see
    /// docs/DESKTOP_AGENT_PROTOCOL.md. Nothing in this codebase writes these fields yet.</summary>
    public string? ActivityApplicationName { get; set; }

    public ActivityType? ActivityType { get; set; }

    public DateTime? ActivityStartedAt { get; set; }

    public string? Password { get; set; }

    /// <summary>
    /// Base32 TOTP shared secret (P2), encrypted at rest via ASP.NET Core Data Protection (see
    /// <c>TwoFactorService</c>'s protector). Present but with <see cref="TwoFactorEnabled"/> still
    /// false means enrolment was started and never confirmed - that pending secret is inert and is
    /// overwritten by the next setup attempt.
    ///
    /// The Data Protection key ring is persisted to a volume (see Program.cs/compose.yaml) so a
    /// container restart does not rotate the keys and lock enrolled users out. A secret written
    /// before this column carried encrypted data cannot be decrypted - see the P2 remediation notes.
    /// </summary>
    public string? TwoFactorSecret { get; set; }

    public bool TwoFactorEnabled { get; set; }

    public DateTime? TwoFactorEnabledAt { get; set; }

    /// <summary>
    /// The last TOTP time-step this account successfully consumed. A code stays valid for its whole
    /// step (plus the verification window), so without this the same six digits could be replayed
    /// within that span - by anyone who shoulder-surfed or intercepted them.
    /// </summary>
    public long? TwoFactorLastUsedStep { get; set; }

    public DateTime? Disabled { get; set; }

    /// <summary>
    /// Set when the user requests account deletion. Alongside <see cref="Disabled"/> (set to the
    /// same timestamp), this hides/blocks the account exactly like an admin-disabled one for the
    /// duration of the grace period (see <c>GlobalConstants.AccountDeletionGracePeriodDays</c>), except
    /// that logging back in during the window is still allowed and cancels the deletion (both fields
    /// are cleared). Once <see cref="CleanupBackgroundService"/> purges the account after the grace
    /// period, this is cleared back to null while <see cref="Disabled"/> is left set permanently, so
    /// the account stays blocked forever without re-opening the login carve-out.
    /// </summary>
    public DateTime? DeletionRequestedAt { get; set; }

    public int FailedLoginAttempts { get; set; }

    public DateTime? LockoutEnd { get; set; }

    public ICollection<Session> Sessions { get; set; }
}
