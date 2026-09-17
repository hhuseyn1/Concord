namespace Concord.Application.Models;

public static class GlobalConstants
{
    public const string DefaultLocale = "az-AZ";

    public static string[] SupportedLocales = new string[] { "az-AZ", "en-EN" };

    public const int TimeZoneOffsetHours = 4;

    public const int MaxPageSize = 30;

    public const int AccountDeletionGracePeriodDays = 30;
}