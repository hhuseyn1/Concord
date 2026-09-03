using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class UpdateProfileRequest
{
    [JsonPropertyName("Name")]
    public string? Name { get; set; }

    [JsonPropertyName("Surname")]
    public string? Surname { get; set; }

    [JsonPropertyName("Username")]
    public string? Username { get; set; }

    [JsonPropertyName("AvatarUrl")]
    public string? AvatarUrl { get; set; }
}
