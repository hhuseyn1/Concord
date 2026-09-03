using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class SessionResponse
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("DeviceLabel")]
    public string? DeviceLabel { get; set; }

    [JsonPropertyName("Browser")]
    public string? Browser { get; set; }

    [JsonPropertyName("OS")]
    public string? OS { get; set; }

    [JsonPropertyName("IpAddress")]
    public string? IpAddress { get; set; }

    [JsonPropertyName("Created")]
    public DateTime Created { get; set; }

    [JsonPropertyName("LastActiveAt")]
    public DateTime LastActiveAt { get; set; }

    [JsonPropertyName("IsCurrent")]
    public bool IsCurrent { get; set; }
}
