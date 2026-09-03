using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

/// <summary>One row of a global search result (P2.3) - a normalized view over either a channel
/// message or a DM message, discriminated by <see cref="SourceType"/> so the frontend can navigate
/// to the right place (a channel within a server, or a DM conversation) without needing two
/// differently-shaped result lists merged client-side.</summary>
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
