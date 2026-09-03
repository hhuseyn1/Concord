using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ConfirmEmailRequest
{
    [JsonPropertyName("Token")]
    public string? Token { get; set; }
}
