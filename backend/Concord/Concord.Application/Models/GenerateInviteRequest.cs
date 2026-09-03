using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class GenerateInviteRequest
{
    [JsonPropertyName("ExpiresAtUtc")]
    public DateTime? ExpiresAtUtc { get; set; }

    [JsonPropertyName("MaxUses")]
    public int? MaxUses { get; set; }
}
