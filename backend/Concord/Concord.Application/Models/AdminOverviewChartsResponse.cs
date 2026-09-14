using System.Text.Json.Serialization;

namespace Concord.Application.Models;

/// <summary>Date-filterable chart data for the admin overview page (P4) - split out from
/// <see cref="AdminOverviewResponse"/> since the stat tiles are fetched once per page load while
/// these two need to be refetched independently whenever the admin changes the date range.</summary>
public class AdminOverviewChartsResponse
{
    /// <summary>One entry per calendar day (UTC) across the requested range, oldest first, including
    /// days with zero signups - a consistent x-axis for the overview's new-users chart.</summary>
    [JsonPropertyName("UserGrowth")]
    public List<AdminUserGrowthPoint> UserGrowth { get; set; } = [];

    /// <summary>Counts of subscription rows created within the requested range, by status - see
    /// <see cref="AdminSubscriptionStatusBreakdown"/>.</summary>
    [JsonPropertyName("SubscriptionsByStatus")]
    public AdminSubscriptionStatusBreakdown SubscriptionsByStatus { get; set; } = new();
}
