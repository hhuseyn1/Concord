using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ConfirmPasswordRequest
{
    [JsonPropertyName("Password")]
    public string? Password { get; set; }
}
