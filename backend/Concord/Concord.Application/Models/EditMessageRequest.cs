using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class EditMessageRequest
{
    [JsonPropertyName("Content")]
    public string? Content { get; set; }
}
