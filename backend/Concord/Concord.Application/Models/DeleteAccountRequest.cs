using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class DeleteAccountRequest
{
    [JsonPropertyName("Password")]
    public string? Password { get; set; }
}
