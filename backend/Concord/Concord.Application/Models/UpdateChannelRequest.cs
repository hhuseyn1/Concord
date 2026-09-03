using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class UpdateChannelRequest
{
    [JsonPropertyName("Name")]
    public string? Name { get; set; }
}
