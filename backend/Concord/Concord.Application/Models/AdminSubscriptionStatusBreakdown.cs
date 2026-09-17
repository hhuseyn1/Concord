using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class AdminSubscriptionStatusBreakdown
{
    [JsonPropertyName("Active")]
    public int Active { get; set; }

    [JsonPropertyName("PastDue")]
    public int PastDue { get; set; }

    [JsonPropertyName("Canceled")]
    public int Canceled { get; set; }
}
