using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ForwardMessageRequest
{
    [JsonPropertyName("TargetChannelId")]
    public Guid? TargetChannelId { get; set; }

    [JsonPropertyName("TargetConversationId")]
    public Guid? TargetConversationId { get; set; }
}
