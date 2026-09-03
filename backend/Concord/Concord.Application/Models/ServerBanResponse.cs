using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ServerBanResponse
{
    [JsonPropertyName("User")]
    public PublicProfileResponse User { get; set; } = null!;

    [JsonPropertyName("BannedByUserId")]
    public Guid BannedByUserId { get; set; }

    [JsonPropertyName("Reason")]
    public string? Reason { get; set; }

    [JsonPropertyName("ExpiresAtUtc")]
    public DateTime? ExpiresAtUtc { get; set; }

    [JsonPropertyName("BannedAt")]
    public DateTime BannedAt { get; set; }
}
