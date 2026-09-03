using System.Text.Json.Serialization;

namespace Concord.Application.Models;

/// <summary>
/// What the approving device is shown before it decides. Approving blind is the central risk of a
/// cross-device sign-in, so the device details are surfaced rather than just the code.
/// </summary>
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
