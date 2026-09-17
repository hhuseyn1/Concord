using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class GlobalSearchRequest
{
    [JsonPropertyName("Query")]
    public string Query { get; set; } = string.Empty;

    [JsonPropertyName("Page")]
    public int Page { get; set; }

    [JsonPropertyName("PageSize")]
    public int PageSize { get; set; }
}
