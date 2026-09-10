namespace Concord.Application.Models;

public static class GlobalConstants
{
    public const string DefaultLocale = "az-AZ";

    public static string[] SupportedLocales = new string[] { "az-AZ", "en-EN" };

    public const int TimeZoneOffsetHours = 4;

    public const int MaxPageSize = 30;

    /// <summary>
    /// How long a self-service account deletion stays cancellable (by logging back in) before
    /// <c>CleanupBackgroundService</c> purges it permanently.
    /// </summary>
    public const int AccountDeletionGracePeriodDays = 30;
}