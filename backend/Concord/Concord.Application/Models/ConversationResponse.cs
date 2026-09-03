using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ConversationResponse
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("OtherUser")]
    public PublicProfileResponse OtherUser { get; set; } = null!;

    [JsonPropertyName("LastMessage")]
    public DirectMessageResponse? LastMessage { get; set; }

    [JsonPropertyName("LastMessageAt")]
    public DateTime? LastMessageAt { get; set; }

    [JsonPropertyName("UnreadCount")]
    public int UnreadCount { get; set; }
}
