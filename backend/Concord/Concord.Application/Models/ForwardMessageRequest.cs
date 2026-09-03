using System.Text.Json.Serialization;

namespace Concord.Application.Models;

/// <summary>Exactly one of <see cref="TargetChannelId"/>/<see cref="TargetConversationId"/> must be
/// set (P2.5) - the destination can be a channel or a DM conversation regardless of the source.</summary>
public class ForwardMessageRequest
{
    [JsonPropertyName("TargetChannelId")]
    public Guid? TargetChannelId { get; set; }

    [JsonPropertyName("TargetConversationId")]
    public Guid? TargetConversationId { get; set; }
}
