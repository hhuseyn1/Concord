using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class PortalSessionResponse
{
    [JsonPropertyName("Url")]
    public string? Url { get; set; }
}
