using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ReactionRequest
{
    [JsonPropertyName("Emoji")]
    public string? Emoji { get; set; }
}
