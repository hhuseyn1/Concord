using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class UpdateCustomStatusRequest
{
    [JsonPropertyName("Emoji")]
    public string? Emoji { get; set; }

    [JsonPropertyName("Text")]
    public string? Text { get; set; }

    [JsonPropertyName("ExpiryPreset")]
    public CustomStatusExpiryPreset ExpiryPreset { get; set; }
}
