using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class CreateReportRequest
{
    [JsonPropertyName("TargetType")]
    public ReportTargetType TargetType { get; set; }

    [JsonPropertyName("TargetId")]
    public Guid TargetId { get; set; }

    [JsonPropertyName("Reason")]
    public string? Reason { get; set; }
}
