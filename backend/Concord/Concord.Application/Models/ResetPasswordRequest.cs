using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ResetPasswordRequest
{
    [JsonPropertyName("NewPassword")]
    public string? NewPassword { get; set; }
}
