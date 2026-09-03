using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class TwoFactorCodeRequest
{
    [JsonPropertyName("Code")]
    public string? Code { get; set; }
}
