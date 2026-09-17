using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class AdminUserGrowthPoint
{
    [JsonPropertyName("Date")]
    public DateOnly Date { get; set; }

    [JsonPropertyName("Count")]
    public int Count { get; set; }
}
