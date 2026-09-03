using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class VoiceTokenResponse
{
    [JsonPropertyName("Token")]
    public string? Token { get; set; }

    [JsonPropertyName("Url")]
    public string? Url { get; set; }
}
