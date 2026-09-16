using System.Text.Json.Serialization;

namespace Concord.Application.Models;

/// <summary>One calendar month's new-user count for the admin overview chart (P4) - see
/// <see cref="AdminService.GetUserGrowthAsync"/>. Always one entry per month of the requested year
/// (<c>Date</c> is the first day of that month), including months with zero signups, so a bar chart
/// has a consistent x-axis.</summary>
public class AdminUserGrowthPoint
{
    [JsonPropertyName("Date")]
    public DateOnly Date { get; set; }

    [JsonPropertyName("Count")]
    public int Count { get; set; }
}
