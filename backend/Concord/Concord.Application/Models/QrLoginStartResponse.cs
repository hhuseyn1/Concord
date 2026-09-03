using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class QrLoginStartResponse
{
    /// <summary>Shown under the QR so the flow still works when a camera is not an option.</summary>
    [JsonPropertyName("UserCode")]
    public string? UserCode { get; set; }

    /// <summary>
    /// The browser's secret for collecting the resulting session. Held in memory for this attempt
    /// only - it is deliberately absent from the QR, so photographing the screen does not let anyone
    /// else claim the session.
    /// </summary>
    [JsonPropertyName("PollingToken")]
    public string? PollingToken { get; set; }

    /// <summary>Deep link encoded in the QR - opens the approval screen on an already-signed-in device.</summary>
    [JsonPropertyName("ApprovalUrl")]
    public string? ApprovalUrl { get; set; }

    [JsonPropertyName("QrCodeSvg")]
    public string? QrCodeSvg { get; set; }

    [JsonPropertyName("ExpiresAtUtc")]
    public DateTime ExpiresAtUtc { get; set; }
}
