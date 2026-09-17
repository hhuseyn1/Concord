using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class ReportResponse
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("Reporter")]
    public PublicProfileResponse Reporter { get; set; } = null!;

    [JsonPropertyName("TargetType")]
    public ReportTargetType TargetType { get; set; }

    [JsonPropertyName("TargetId")]
    public Guid TargetId { get; set; }

    [JsonPropertyName("TargetSnippet")]
    public string? TargetSnippet { get; set; }

    [JsonPropertyName("Reason")]
    public string Reason { get; set; } = null!;

    [JsonPropertyName("Status")]
    public ReportStatus Status { get; set; }

    [JsonPropertyName("ResolvedByUserId")]
    public Guid? ResolvedByUserId { get; set; }

    [JsonPropertyName("ResolvedAtUtc")]
    public DateTime? ResolvedAtUtc { get; set; }

    [JsonPropertyName("CreatedUtc")]
    public DateTime CreatedUtc { get; set; }
}
