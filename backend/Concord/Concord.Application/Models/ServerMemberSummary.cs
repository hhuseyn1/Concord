using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ServerMemberSummary
{
    [JsonPropertyName("User")]
    public PublicProfileResponse User { get; set; } = null!;

    [JsonPropertyName("JoinedAt")]
    public DateTime JoinedAt { get; set; }

    [JsonPropertyName("IsMuted")]
    public bool IsMuted { get; set; }

    [JsonPropertyName("TimedOutUntil")]
    public DateTime? TimedOutUntil { get; set; }
}
