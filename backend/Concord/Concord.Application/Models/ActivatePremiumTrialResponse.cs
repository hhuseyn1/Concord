using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ActivatePremiumTrialResponse
{
    [JsonPropertyName("Balance")]
    public int Balance { get; set; }

    [JsonPropertyName("PremiumTrialExpiresAt")]
    public DateTime PremiumTrialExpiresAt { get; set; }
}
