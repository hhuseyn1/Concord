using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class TwoFactorLoginRequest
{
    [JsonPropertyName("TwoFactorToken")]
    public string? TwoFactorToken { get; set; }

    [JsonPropertyName("Code")]
    public string? Code { get; set; }

    [JsonPropertyName("RememberMe")]
    public bool RememberMe { get; set; }
}
