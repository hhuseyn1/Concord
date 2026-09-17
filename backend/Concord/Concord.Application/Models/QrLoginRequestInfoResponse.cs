using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class QrLoginRequestInfoResponse
{
    [JsonPropertyName("UserCode")]
    public string? UserCode { get; set; }

    [JsonPropertyName("DeviceLabel")]
    public string? DeviceLabel { get; set; }

    [JsonPropertyName("Browser")]
    public string? Browser { get; set; }

    [JsonPropertyName("OS")]
    public string? OS { get; set; }

    [JsonPropertyName("IpAddress")]
    public string? IpAddress { get; set; }

    [JsonPropertyName("RequestedAt")]
    public DateTime RequestedAt { get; set; }

    [JsonPropertyName("ExpiresAtUtc")]
    public DateTime ExpiresAtUtc { get; set; }
}
