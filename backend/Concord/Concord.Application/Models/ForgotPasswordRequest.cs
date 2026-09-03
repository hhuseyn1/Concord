using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ForgotPasswordRequest
{
    [JsonPropertyName("Email")]
    public string? Email { get; set; }
}
