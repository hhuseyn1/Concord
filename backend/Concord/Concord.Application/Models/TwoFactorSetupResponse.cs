using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class TwoFactorSetupResponse
{
    [JsonPropertyName("SecretKey")]
    public string? SecretKey { get; set; }

    [JsonPropertyName("OtpAuthUri")]
    public string? OtpAuthUri { get; set; }

    [JsonPropertyName("QrCodeSvg")]
    public string? QrCodeSvg { get; set; }
}
