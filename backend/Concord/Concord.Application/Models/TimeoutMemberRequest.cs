using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class TimeoutMemberRequest
{
    /// <summary>How long the timeout lasts, in minutes. Capped server-side at 28 days.</summary>
    [JsonPropertyName("DurationMinutes")]
    public int DurationMinutes { get; set; }

    [JsonPropertyName("Reason")]
    public string? Reason { get; set; }
}
