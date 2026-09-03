using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class RefreshRequest
{
    [JsonPropertyName("AccessToken")]
    public string? AccessToken { get; set; }

    [JsonPropertyName("RefreshToken")]
    public string? RefreshToken { get; set; }
}