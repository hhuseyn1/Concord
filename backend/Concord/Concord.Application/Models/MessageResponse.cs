using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class MessageResponse
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("ChannelId")]
    public Guid ChannelId { get; set; }

    [JsonPropertyName("Sender")]
    public PublicProfileResponse Sender { get; set; } = null!;

    [JsonPropertyName("Content")]
    public string? Content { get; set; }

    [JsonPropertyName("Created")]
    public DateTime Created { get; set; }

    [JsonPropertyName("EditedAtUtc")]
    public DateTime? EditedAtUtc { get; set; }

    [JsonPropertyName("AttachmentUrl")]
    public string? AttachmentUrl { get; set; }

    [JsonPropertyName("ReplyToMessageId")]
    public Guid? ReplyToMessageId { get; set; }

    [JsonPropertyName("Reactions")]
    public List<ReactionSummaryResponse> Reactions { get; set; } = [];

    [JsonPropertyName("PinnedAt")]
    public DateTime? PinnedAt { get; set; }

    [JsonPropertyName("PinnedByUserId")]
    public Guid? PinnedByUserId { get; set; }

    [JsonPropertyName("ForwardedFromSenderId")]
    public Guid? ForwardedFromSenderId { get; set; }

    [JsonPropertyName("ForwardedFromCreatedAt")]
    public DateTime? ForwardedFromCreatedAt { get; set; }

    [JsonPropertyName("MentionedUserIds")]
    public List<Guid> MentionedUserIds { get; set; } = [];

    [JsonPropertyName("MentionsEveryone")]
    public bool MentionsEveryone { get; set; }
}
