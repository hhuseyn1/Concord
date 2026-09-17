using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class MemberModerationResponse
{
    [JsonPropertyName("UserId")]
    public Guid UserId { get; set; }

    [JsonPropertyName("IsMuted")]
    public bool IsMuted { get; set; }

    [JsonPropertyName("TimedOutUntil")]
    public DateTime? TimedOutUntil { get; set; }

    [JsonPropertyName("TimedOutByUserId")]
    public Guid? TimedOutByUserId { get; set; }

    [JsonPropertyName("TimeoutReason")]
    public string? TimeoutReason { get; set; }
}
