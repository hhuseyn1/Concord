using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class TokenResponse
{
    [JsonPropertyName("AccessToken")]
    public string? AccessToken { get; set; }

    [JsonPropertyName("RefreshToken")]
    public string? RefreshToken { get; set; }

    [JsonPropertyName("AccessTokenExpires")]
    public DateTime? AccessTokenExpires { get; set; }

    [JsonPropertyName("RefreshTokenExpires")]
    public DateTime? RefreshTokenExpires { get; set; }

    /// <summary>
    /// P2: set when the password was correct but the account has a second factor. In that case no
    /// session exists yet and <see cref="AccessToken"/>/<see cref="RefreshToken"/> are both null -
    /// the caller must complete <c>Login/TwoFactor</c> with <see cref="TwoFactorToken"/>.
    /// </summary>
    [JsonPropertyName("TwoFactorRequired")]
    public bool TwoFactorRequired { get; set; }

    /// <summary>
    /// Short-lived token proving the password step passed. Issued under a separate audience so the
    /// API's own bearer scheme rejects it outright - it can buy nothing but a second-factor attempt.
    /// </summary>
    [JsonPropertyName("TwoFactorToken")]
    public string? TwoFactorToken { get; set; }

    /// <summary>
    /// Set when registration succeeded but the account is not yet usable until the verification
    /// email is confirmed. In that case every token field is null - there is no session yet.
    /// </summary>
    [JsonPropertyName("EmailConfirmationRequired")]
    public bool EmailConfirmationRequired { get; set; }
}