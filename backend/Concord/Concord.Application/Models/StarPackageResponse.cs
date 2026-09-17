using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class StarPackageResponse
{
    [JsonPropertyName("Id")]
    public string Id { get; set; } = null!;

    [JsonPropertyName("Stars")]
    public int Stars { get; set; }

    [JsonPropertyName("PriceAmount")]
    public decimal PriceAmount { get; set; }

    [JsonPropertyName("Currency")]
    public string Currency { get; set; } = null!;
}
