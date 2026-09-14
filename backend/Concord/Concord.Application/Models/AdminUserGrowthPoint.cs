using System.Text.Json.Serialization;

namespace Concord.Application.Models;

/// <summary>One day's new-user count for the admin overview chart (P4) - see
/// <see cref="AdminOverviewResponse.UserGrowth"/>. Always one entry per calendar day in the window,
/// including days with zero signups, so a bar chart has a consistent x-axis.</summary>
public class AdminUserGrowthPoint
{
    [JsonPropertyName("Date")]
    public DateOnly Date { get; set; }

    [JsonPropertyName("Count")]
    public int Count { get; set; }
}
