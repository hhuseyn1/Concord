using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class QrLoginStartResponse
{
    [JsonPropertyName("UserCode")]
    public string? UserCode { get; set; }

    [JsonPropertyName("PollingToken")]
    public string? PollingToken { get; set; }

    [JsonPropertyName("ApprovalUrl")]
    public string? ApprovalUrl { get; set; }

    [JsonPropertyName("QrCodeSvg")]
    public string? QrCodeSvg { get; set; }

    [JsonPropertyName("ExpiresAtUtc")]
    public DateTime ExpiresAtUtc { get; set; }
}
