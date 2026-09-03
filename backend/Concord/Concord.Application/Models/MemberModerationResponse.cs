using System.Text.Json.Serialization;

namespace Concord.Application.Models;

/// <summary>Moderation state of one member - drives the mute/timeout controls on their row.</summary>
public class MemberModerationResponse
{
    [JsonPropertyName("UserId")]
    public Guid UserId { get; set; }

    [JsonPropertyName("IsMuted")]
    public bool IsMuted { get; set; }

    /// <summary>Null when there is no timeout, or when the last one has already lapsed.</summary>
    [JsonPropertyName("TimedOutUntil")]
    public DateTime? TimedOutUntil { get; set; }

    [JsonPropertyName("TimedOutByUserId")]
    public Guid? TimedOutByUserId { get; set; }

    [JsonPropertyName("TimeoutReason")]
    public string? TimeoutReason { get; set; }
}
