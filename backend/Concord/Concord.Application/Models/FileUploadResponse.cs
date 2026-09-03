using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class FileUploadResponse
{
    [JsonPropertyName("Url")]
    public string? Url { get; set; }
}
