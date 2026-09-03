using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class TwoFactorSetupResponse
{
    /// <summary>Base32 secret, space-grouped for readable manual entry when a QR cannot be scanned.</summary>
    [JsonPropertyName("SecretKey")]
    public string? SecretKey { get; set; }

    /// <summary>Standard <c>otpauth://totp/...</c> URI - what the QR encodes.</summary>
    [JsonPropertyName("OtpAuthUri")]
    public string? OtpAuthUri { get; set; }

    /// <summary>The same URI rendered as an SVG data URI, ready for an <c>img src</c>.</summary>
    [JsonPropertyName("QrCodeSvg")]
    public string? QrCodeSvg { get; set; }
}
