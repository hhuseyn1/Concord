using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class UpdateRoleRequest
{
    [JsonPropertyName("Name")]
    public string? Name { get; set; }

    [JsonPropertyName("Color")]
    public string? Color { get; set; }

    [JsonPropertyName("Permissions")]
    public long Permissions { get; set; }
}
