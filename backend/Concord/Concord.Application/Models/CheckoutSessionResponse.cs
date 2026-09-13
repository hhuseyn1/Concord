using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class CheckoutSessionResponse
{
    [JsonPropertyName("Url")]
    public string? Url { get; set; }
}
