using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class PagedResult<T>
{
    [JsonPropertyName("Items")]
    public List<T> Items { get; set; } = [];

    [JsonPropertyName("Page")]
    public int Page { get; set; }

    [JsonPropertyName("PageSize")]
    public int PageSize { get; set; }

    [JsonPropertyName("TotalCount")]
    public int TotalCount { get; set; }
}
