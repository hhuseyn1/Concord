namespace Concord.Domain.Entities;

/// <summary>
/// A single-use backup code for signing in when the authenticator app is unavailable (P2).
///
/// Stored hashed with the same hasher as passwords: a leaked database must not yield working codes,
/// and unlike the TOTP secret these never need to be read back - only compared against.
/// </summary>
public class TwoFactorRecoveryCode : BaseEntity
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public string? CodeHash { get; set; }

    /// <summary>Set the moment the code is redeemed. Spent codes are kept, not deleted, so the
    /// remaining count stays honest and a redemption is visible after the fact.</summary>
    public DateTime? UsedAt { get; set; }
}
