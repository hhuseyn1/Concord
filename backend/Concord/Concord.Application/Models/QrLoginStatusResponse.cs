using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class QrLoginStatusResponse
{
    [JsonPropertyName("Status")]
    public QrLoginStatus Status { get; set; }

    [JsonPropertyName("Expired")]
    public bool Expired { get; set; }

    [JsonPropertyName("Tokens")]
    public TokenResponse? Tokens { get; set; }
}
