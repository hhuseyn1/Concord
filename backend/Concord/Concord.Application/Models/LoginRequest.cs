using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class LoginRequest
{
    [JsonPropertyName("Email")]
    public string? Email { get; set; }

    [JsonPropertyName("Password")]
    public string? Password { get; set; }

    [JsonPropertyName("RememberMe")]
    public bool RememberMe { get; set; }
}