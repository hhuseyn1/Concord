using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class NotificationResponse
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("Type")]
    public NotificationType Type { get; set; }

    [JsonPropertyName("RelatedUser")]
    public PublicProfileResponse? RelatedUser { get; set; }

    [JsonPropertyName("IsRead")]
    public bool IsRead { get; set; }

    [JsonPropertyName("ReadAt")]
    public DateTime? ReadAt { get; set; }

    [JsonPropertyName("Created")]
    public DateTime Created { get; set; }

    [JsonPropertyName("ContextServerId")]
    public Guid? ContextServerId { get; set; }

    [JsonPropertyName("ContextChannelId")]
    public Guid? ContextChannelId { get; set; }

    [JsonPropertyName("ContextConversationId")]
    public Guid? ContextConversationId { get; set; }

    [JsonPropertyName("ContextMessageId")]
    public Guid? ContextMessageId { get; set; }

    [JsonPropertyName("Reason")]
    public string? Reason { get; set; }
}
