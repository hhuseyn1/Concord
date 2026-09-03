using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class VoiceParticipantSummary
{
    [JsonPropertyName("UserId")]
    public Guid UserId { get; set; }

    [JsonPropertyName("Identity")]
    public string? Identity { get; set; }

    [JsonPropertyName("JoinedAt")]
    public DateTime JoinedAt { get; set; }
}
