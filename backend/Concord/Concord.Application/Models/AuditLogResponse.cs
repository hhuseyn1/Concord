using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class AuditLogResponse
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("Actor")]
    public PublicProfileResponse Actor { get; set; } = null!;

    [JsonPropertyName("Action")]
    public string Action { get; set; } = null!;

    [JsonPropertyName("TargetType")]
    public string? TargetType { get; set; }

    [JsonPropertyName("TargetId")]
    public Guid? TargetId { get; set; }

    [JsonPropertyName("Metadata")]
    public string? Metadata { get; set; }

    [JsonPropertyName("CreatedUtc")]
    public DateTime CreatedUtc { get; set; }
}
