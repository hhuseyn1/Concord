using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class DisableTwoFactorRequest
{
    [JsonPropertyName("Password")]
    public string? Password { get; set; }

    [JsonPropertyName("Code")]
    public string? Code { get; set; }
}
