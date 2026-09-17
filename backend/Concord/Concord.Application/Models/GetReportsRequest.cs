using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class GetReportsRequest
{
    [JsonPropertyName("Page")]
    public int Page { get; set; }

    [JsonPropertyName("PageSize")]
    public int PageSize { get; set; }

    [JsonPropertyName("Status")]
    public ReportStatus? Status { get; set; }

    [JsonPropertyName("Search")]
    public string? Search { get; set; }

    [JsonPropertyName("SortBy")]
    public string? SortBy { get; set; }

    [JsonPropertyName("SortDirection")]
    public string? SortDirection { get; set; }
}
