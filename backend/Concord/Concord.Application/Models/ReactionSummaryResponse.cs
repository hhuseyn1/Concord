using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ReactionSummaryResponse
{
    [JsonPropertyName("Emoji")]
    public string Emoji { get; set; } = string.Empty;

    [JsonPropertyName("UserIds")]
    public List<Guid> UserIds { get; set; } = [];
}
