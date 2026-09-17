using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class GetAdminSubscriptionsRequest
{
    [JsonPropertyName("Page")]
    public int Page { get; set; }

    [JsonPropertyName("PageSize")]
    public int PageSize { get; set; }

    [JsonPropertyName("Status")]
    public SubscriptionStatus? Status { get; set; }

    [JsonPropertyName("Search")]
    public string? Search { get; set; }

    [JsonPropertyName("SortBy")]
    public string? SortBy { get; set; }

    [JsonPropertyName("SortDirection")]
    public string? SortDirection { get; set; }

    [JsonPropertyName("FromUtc")]
    public DateTime? FromUtc { get; set; }

    [JsonPropertyName("ToUtc")]
    public DateTime? ToUtc { get; set; }
}
