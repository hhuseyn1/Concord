using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class StarWalletResponse
{
    [JsonPropertyName("Balance")]
    public int Balance { get; set; }

    /// <summary>True if the user's Stars-funded trial specifically is unexpired (distinct from paying
    /// via Stripe).</summary>
    [JsonPropertyName("PremiumTrialActive")]
    public bool PremiumTrialActive { get; set; }

    [JsonPropertyName("PremiumTrialExpiresAt")]
    public DateTime? PremiumTrialExpiresAt { get; set; }

    /// <summary>True if the user currently has Premium access from any source - an active/past-due
    /// Stripe subscription, or an unexpired Stars trial.</summary>
    [JsonPropertyName("HasActivePremium")]
    public bool HasActivePremium { get; set; }
}
