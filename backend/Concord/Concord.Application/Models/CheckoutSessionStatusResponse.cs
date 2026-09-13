using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class CheckoutSessionStatusResponse
{
    [JsonPropertyName("Status")]
    public string? Status { get; set; }
}
