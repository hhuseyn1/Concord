using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class TimeoutMemberRequest
{
    [JsonPropertyName("DurationMinutes")]
    public int DurationMinutes { get; set; }

    [JsonPropertyName("Reason")]
    public string? Reason { get; set; }
}
