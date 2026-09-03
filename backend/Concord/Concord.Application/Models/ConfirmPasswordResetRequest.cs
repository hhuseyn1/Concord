using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ConfirmPasswordResetRequest
{
    [JsonPropertyName("Token")]
    public string? Token { get; set; }

    [JsonPropertyName("NewPassword")]
    public string? NewPassword { get; set; }
}
