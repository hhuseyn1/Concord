using System.Text.Json.Serialization;

namespace Concord.Application.Models;

/// <summary>Counts of <see cref="Domain.Entities.Subscription"/> rows by <see cref="Enums.SubscriptionStatus"/>
/// for the admin overview chart (P4). Like <see cref="AdminService.GetSubscriptionsAsync"/>, this counts
/// rows, not deduplicated users - a user who resubscribed contributes multiple historical rows.</summary>
public class AdminSubscriptionStatusBreakdown
{
    [JsonPropertyName("Active")]
    public int Active { get; set; }

    [JsonPropertyName("PastDue")]
    public int PastDue { get; set; }

    [JsonPropertyName("Canceled")]
    public int Canceled { get; set; }
}
