using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class StarsConfigResponse
{
    [JsonPropertyName("ChatRewardAmount")]
    public int ChatRewardAmount { get; set; }

    [JsonPropertyName("ChatRewardCooldownSeconds")]
    public int ChatRewardCooldownSeconds { get; set; }

    [JsonPropertyName("ChatRewardDailyCap")]
    public int ChatRewardDailyCap { get; set; }

    [JsonPropertyName("PremiumTrialCostStars")]
    public int PremiumTrialCostStars { get; set; }

    [JsonPropertyName("PremiumTrialDurationDays")]
    public int PremiumTrialDurationDays { get; set; }

    [JsonPropertyName("Packages")]
    public List<StarPackageResponse> Packages { get; set; } = [];
}
