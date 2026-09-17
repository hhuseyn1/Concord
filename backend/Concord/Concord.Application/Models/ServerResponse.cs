using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ServerResponse
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("Name")]
    public string? Name { get; set; }

    [JsonPropertyName("OwnerId")]
    public Guid OwnerId { get; set; }

    [JsonPropertyName("IconUrl")]
    public string? IconUrl { get; set; }

    [JsonPropertyName("Created")]
    public DateTime Created { get; set; }

    [JsonPropertyName("JoinedNow")]
    public bool JoinedNow { get; set; }
}
