using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class BanMemberRequest
{
    [JsonPropertyName("Reason")]
    public string? Reason { get; set; }

    [JsonPropertyName("ExpiresAtUtc")]
    public DateTime? ExpiresAtUtc { get; set; }
}
