using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class RecoveryCodesResponse
{
    [JsonPropertyName("Codes")]
    public List<string> Codes { get; set; } = [];
}
