using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class TwoFactorStatusResponse
{
    [JsonPropertyName("Enabled")]
    public bool Enabled { get; set; }

    [JsonPropertyName("EnabledAt")]
    public DateTime? EnabledAt { get; set; }

    [JsonPropertyName("SetupPending")]
    public bool SetupPending { get; set; }

    [JsonPropertyName("RemainingRecoveryCodes")]
    public int RemainingRecoveryCodes { get; set; }
}
