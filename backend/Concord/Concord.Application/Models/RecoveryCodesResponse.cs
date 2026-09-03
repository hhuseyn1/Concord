using System.Text.Json.Serialization;

namespace Concord.Application.Models;

/// <summary>
/// Freshly generated recovery codes. Returned exactly once, at the moment they are created - only
/// their hashes are stored, so this response cannot be reproduced later.
/// </summary>
public class RecoveryCodesResponse
{
    [JsonPropertyName("Codes")]
    public List<string> Codes { get; set; } = [];
}
