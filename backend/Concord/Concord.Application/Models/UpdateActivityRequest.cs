using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class UpdateActivityRequest
{
    [JsonPropertyName("ApplicationName")]
    public string? ApplicationName { get; set; }

    [JsonPropertyName("ActivityType")]
    public ActivityType ActivityType { get; set; }
}
