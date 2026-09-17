using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class GetAuditLogRequest
{
    [JsonPropertyName("Page")]
    public int Page { get; set; }

    [JsonPropertyName("PageSize")]
    public int PageSize { get; set; }

    [JsonPropertyName("ActorEmail")]
    public string? ActorEmail { get; set; }

    [JsonPropertyName("Action")]
    public string? Action { get; set; }

    [JsonPropertyName("FromUtc")]
    public DateTime? FromUtc { get; set; }

    [JsonPropertyName("ToUtc")]
    public DateTime? ToUtc { get; set; }

    [JsonPropertyName("SortDirection")]
    public string? SortDirection { get; set; }
}
