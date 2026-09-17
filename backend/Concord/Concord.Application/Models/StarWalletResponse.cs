using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class StarWalletResponse
{
    [JsonPropertyName("Balance")]
    public int Balance { get; set; }

    [JsonPropertyName("PremiumTrialActive")]
    public bool PremiumTrialActive { get; set; }

    [JsonPropertyName("PremiumTrialExpiresAt")]
    public DateTime? PremiumTrialExpiresAt { get; set; }

    [JsonPropertyName("HasActivePremium")]
    public bool HasActivePremium { get; set; }
}
