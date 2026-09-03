using System.Text.Json.Serialization;

namespace Concord.Application.Models;

/// <summary>Re-authentication for a sensitive action that needs the password but changes nothing about it.</summary>
public class ConfirmPasswordRequest
{
    [JsonPropertyName("Password")]
    public string? Password { get; set; }
}
