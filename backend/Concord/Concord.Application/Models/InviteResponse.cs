using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class InviteResponse
{
    [JsonPropertyName("Code")]
    public string? Code { get; set; }

    [JsonPropertyName("ExpiresAtUtc")]
    public DateTime? ExpiresAtUtc { get; set; }

    [JsonPropertyName("MaxUses")]
    public int? MaxUses { get; set; }

    [JsonPropertyName("UseCount")]
    public int UseCount { get; set; }
}
