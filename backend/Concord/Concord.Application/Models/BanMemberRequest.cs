using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class BanMemberRequest
{
    [JsonPropertyName("Reason")]
    public string? Reason { get; set; }

    /// <summary>When the ban should lapse on its own. Omit for a ban that lasts until it is lifted.</summary>
    [JsonPropertyName("ExpiresAtUtc")]
    public DateTime? ExpiresAtUtc { get; set; }
}
