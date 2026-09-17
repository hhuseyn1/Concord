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

    [JsonPropertyName("TwoFactorRequired")]
    public bool TwoFactorRequired { get; set; }

    [JsonPropertyName("TwoFactorToken")]
    public string? TwoFactorToken { get; set; }

    [JsonPropertyName("EmailConfirmationRequired")]
    public bool EmailConfirmationRequired { get; set; }
}