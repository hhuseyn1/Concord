using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class GlobalSearchResultResponse
{
    [JsonPropertyName("MessageId")]
    public Guid MessageId { get; set; }

    [JsonPropertyName("SourceType")]
    public MessageSourceType SourceType { get; set; }

    [JsonPropertyName("ServerId")]
    public Guid? ServerId { get; set; }

    [JsonPropertyName("ChannelId")]
    public Guid? ChannelId { get; set; }

    [JsonPropertyName("ConversationId")]
    public Guid? ConversationId { get; set; }

    [JsonPropertyName("Sender")]
    public PublicProfileResponse Sender { get; set; } = null!;

    [JsonPropertyName("Content")]
    public string? Content { get; set; }

    [JsonPropertyName("Created")]
    public DateTime Created { get; set; }
}
