using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ChangePasswordRequest
{
    [JsonPropertyName("CurrentPassword")]
    public string? CurrentPassword { get; set; }

    [JsonPropertyName("NewPassword")]
    public string? NewPassword { get; set; }
}
