using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ResendVerificationEmailRequest
{
    [JsonPropertyName("Email")]
    public string? Email { get; set; }
}
