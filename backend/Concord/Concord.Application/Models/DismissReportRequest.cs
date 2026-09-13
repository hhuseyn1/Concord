using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class DismissReportRequest
{
    [JsonPropertyName("Reason")]
    public string? Reason { get; set; }
}
