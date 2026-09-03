using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class UpdateServerRequest
{
    [JsonPropertyName("Name")]
    public string? Name { get; set; }

    [JsonPropertyName("IconUrl")]
    public string? IconUrl { get; set; }
}
