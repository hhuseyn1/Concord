namespace Concord.Application.Models;

/// <summary>
/// Centralized, easily-tunable knobs for the Stars virtual-currency system - modeled on
/// <see cref="GlobalConstants"/>. Nothing in <c>StarsService</c>/<c>StarsController</c> should
/// hardcode any of these numbers directly.
/// </summary>
public static class StarsConstants
{
    /// <summary>Stars credited for a single DM reward-eligible message.</summary>
    public const int ChatRewardAmount = 2;

    /// <summary>Minimum gap, in seconds, between two reward-eligible messages from the same user.</summary>
    public const int ChatRewardCooldownSeconds = 30;

    /// <summary>Maximum Stars a single user can earn from chat rewards per app-local day.</summary>
    public const int ChatRewardDailyCap = 50;

    /// <summary>Trimmed message content shorter than this earns no reward - a cheap spam guard.</summary>
    public const int ChatRewardMinMessageLength = 3;

    /// <summary>Stars debited to activate the Premium trial.</summary>
    public const int PremiumTrialCostStars = 500;

    /// <summary>How many days the Premium trial grants access for once activated.</summary>
    public const int PremiumTrialDurationDays = 14;

    /// <summary>The full catalog of real-money Stars packages, enumerable by both the Config endpoint
    /// and checkout-session creation.</summary>
    public static readonly IReadOnlyList<StarPackage> Packages =
    [
        new StarPackage("stars_100", 100, 0.99m, "usd"),
        new StarPackage("stars_500", 500, 3.99m, "usd"),
        new StarPackage("stars_1000", 1000, 6.99m, "usd"),
        new StarPackage("stars_5000", 5000, 29.99m, "usd")
    ];
}
