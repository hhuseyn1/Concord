namespace Concord.Application.Models;

public static class StarsConstants
{
    public const int ChatRewardAmount = 2;

    public const int ChatRewardCooldownSeconds = 30;

    public const int ChatRewardDailyCap = 50;

    public const int ChatRewardMinMessageLength = 3;

    public const int PremiumTrialCostStars = 500;

    public const int PremiumTrialDurationDays = 14;

    public static readonly IReadOnlyList<StarPackage> Packages =
    [
        new StarPackage("stars_100", 100, 0.99m, "usd"),
        new StarPackage("stars_500", 500, 3.99m, "usd"),
        new StarPackage("stars_1000", 1000, 6.99m, "usd"),
        new StarPackage("stars_5000", 5000, 29.99m, "usd")
    ];
}
