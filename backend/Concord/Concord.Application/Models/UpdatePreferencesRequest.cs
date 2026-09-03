using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class UpdatePreferencesRequest
{
    [JsonPropertyName("Locale")]
    public string? Locale { get; set; }

    [JsonPropertyName("NotificationsMuted")]
    public bool NotificationsMuted { get; set; }

    [JsonPropertyName("NotificationsSoundEnabled")]
    public bool NotificationsSoundEnabled { get; set; }
}
