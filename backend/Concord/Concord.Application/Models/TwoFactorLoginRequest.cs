using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class TwoFactorLoginRequest
{
    /// <summary>The short-lived token returned by the first login step.</summary>
    [JsonPropertyName("TwoFactorToken")]
    public string? TwoFactorToken { get; set; }

    /// <summary>A current TOTP code, or an unused recovery code.</summary>
    [JsonPropertyName("Code")]
    public string? Code { get; set; }

    [JsonPropertyName("RememberMe")]
    public bool RememberMe { get; set; }
}
