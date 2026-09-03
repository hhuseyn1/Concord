using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class DisableTwoFactorRequest
{
    /// <summary>Required: disabling a second factor must not be possible from a stolen session alone.</summary>
    [JsonPropertyName("Password")]
    public string? Password { get; set; }

    /// <summary>A current TOTP code, or an unused recovery code.</summary>
    [JsonPropertyName("Code")]
    public string? Code { get; set; }
}
