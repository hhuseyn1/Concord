using System.Text.Json.Serialization;

namespace Concord.Application.Models;

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

    [JsonPropertyName("HighestRolePosition")]
    public int HighestRolePosition { get; set; }

    [JsonPropertyName("IsMuted")]
    public bool IsMuted { get; set; }

    [JsonPropertyName("TimedOutUntil")]
    public DateTime? TimedOutUntil { get; set; }
}
