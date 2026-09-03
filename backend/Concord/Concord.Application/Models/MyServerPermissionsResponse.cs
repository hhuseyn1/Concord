using System.Text.Json.Serialization;

namespace Concord.Application.Models;

/// <summary>What the calling user may do in one server - drives which controls the UI renders.</summary>
public class MyServerPermissionsResponse
{
    [JsonPropertyName("ServerId")]
    public Guid ServerId { get; set; }

    [JsonPropertyName("IsOwner")]
    public bool IsOwner { get; set; }

    [JsonPropertyName("Permissions")]
    public long Permissions { get; set; }

    [JsonPropertyName("PermissionNames")]
    public List<string> PermissionNames { get; set; } = [];

    /// <summary>Highest role position held; the ceiling for every hierarchy check.</summary>
    [JsonPropertyName("HighestRolePosition")]
    public int HighestRolePosition { get; set; }

    /// <summary>
    /// P1: set when the caller is muted on this server. <c>Permissions</c> already has Speak removed;
    /// this says *why*, so the client can explain the missing control instead of just hiding it.
    /// </summary>
    [JsonPropertyName("IsMuted")]
    public bool IsMuted { get; set; }

    /// <summary>P1: when the caller's timeout lifts, or null if they are not timed out.</summary>
    [JsonPropertyName("TimedOutUntil")]
    public DateTime? TimedOutUntil { get; set; }
}
