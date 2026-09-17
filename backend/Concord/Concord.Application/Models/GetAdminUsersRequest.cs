using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class GetAdminUsersRequest
{
    [JsonPropertyName("Page")]
    public int Page { get; set; }

    [JsonPropertyName("PageSize")]
    public int PageSize { get; set; }

    [JsonPropertyName("Search")]
    public string? Search { get; set; }

    [JsonPropertyName("SortBy")]
    public string? SortBy { get; set; }

    [JsonPropertyName("SortDirection")]
    public string? SortDirection { get; set; }
}
