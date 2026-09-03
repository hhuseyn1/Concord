using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class RegisterPushTokenRequest
{
    [JsonPropertyName("Token")]
    public string? Token { get; set; }

    [JsonPropertyName("Platform")]
    public PushPlatform Platform { get; set; }
}
