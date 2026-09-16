using System.Text.Json.Serialization;

namespace Concord.Application.Models;

/// <summary>Date-filterable chart data for the admin overview page (P4) - split out from
/// <see cref="AdminOverviewResponse"/> since the stat tiles are fetched once per page load while
/// this needs to be refetched independently whenever the admin changes the date range. New-user
/// growth is served separately by <c>Admin/Overview/UserGrowth</c> (see
/// <see cref="AdminService.GetUserGrowthAsync"/>), since it's filtered by year rather than a date
/// range.</summary>
public class AdminOverviewChartsResponse
{
    /// <summary>Counts of subscription rows created within the requested range, by status - see
    /// <see cref="AdminSubscriptionStatusBreakdown"/>.</summary>
    [JsonPropertyName("SubscriptionsByStatus")]
    public AdminSubscriptionStatusBreakdown SubscriptionsByStatus { get; set; } = new();
}
