using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class AdminOverviewChartsResponse
{
    [JsonPropertyName("SubscriptionsByStatus")]
    public AdminSubscriptionStatusBreakdown SubscriptionsByStatus { get; set; } = new();
}
