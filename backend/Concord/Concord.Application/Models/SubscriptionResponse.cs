using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class SubscriptionResponse
{
    [JsonPropertyName("Status")]
    public string Status { get; set; } = "None";

    [JsonPropertyName("CurrentPeriodEnd")]
    public DateTime? CurrentPeriodEnd { get; set; }

    [JsonPropertyName("CancelAtPeriodEnd")]
    public bool CancelAtPeriodEnd { get; set; }
}
