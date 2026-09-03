using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

/// <summary>Ingestion contract for a future Desktop Presence Agent (P2.8) - see
/// docs/DESKTOP_AGENT_PROTOCOL.md. A null <see cref="ApplicationName"/> clears the current activity
/// (the agent detected the user is no longer in a tracked app/game).</summary>
public class UpdateActivityRequest
{
    [JsonPropertyName("ApplicationName")]
    public string? ApplicationName { get; set; }

    [JsonPropertyName("ActivityType")]
    public ActivityType ActivityType { get; set; }
}
