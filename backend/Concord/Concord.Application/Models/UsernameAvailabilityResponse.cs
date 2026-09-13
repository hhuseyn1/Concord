using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class UsernameAvailabilityResponse
{
    [JsonPropertyName("Available")]
    public bool Available { get; set; }
}
