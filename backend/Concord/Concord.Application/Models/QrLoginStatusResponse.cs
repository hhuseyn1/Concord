using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

/// <summary>
/// Poll result for the waiting browser. <see cref="Tokens"/> is populated exactly once, on the first
/// poll after approval; the session is marked consumed in the same request.
/// </summary>
public class QrLoginStatusResponse
{
    [JsonPropertyName("Status")]
    public QrLoginStatus Status { get; set; }

    /// <summary>True once the request has lapsed. The browser should start a new one rather than wait.</summary>
    [JsonPropertyName("Expired")]
    public bool Expired { get; set; }

    [JsonPropertyName("Tokens")]
    public TokenResponse? Tokens { get; set; }
}
