using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class SendMessageRequest
{
    [JsonPropertyName("Content")]
    public string? Content { get; set; }

    [JsonPropertyName("AttachmentUrl")]
    public string? AttachmentUrl { get; set; }

    [JsonPropertyName("ReplyToMessageId")]
    public Guid? ReplyToMessageId { get; set; }
}
