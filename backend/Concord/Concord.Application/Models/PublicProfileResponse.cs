using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class PublicProfileResponse
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("Username")]
    public string? Username { get; set; }

    [JsonPropertyName("Name")]
    public string? Name { get; set; }

    [JsonPropertyName("Surname")]
    public string? Surname { get; set; }

    [JsonPropertyName("AvatarUrl")]
    public string? AvatarUrl { get; set; }

    [JsonPropertyName("Created")]
    public DateTime Created { get; set; }

    [JsonPropertyName("Status")]
    public PresenceStatus Status { get; set; }

    [JsonPropertyName("LastSeenAt")]
    public DateTime? LastSeenAt { get; set; }

    [JsonPropertyName("CustomStatusEmoji")]
    public string? CustomStatusEmoji { get; set; }

    [JsonPropertyName("CustomStatusText")]
    public string? CustomStatusText { get; set; }

    [JsonPropertyName("RelationshipStatus")]
    public FriendRelationshipStatus RelationshipStatus { get; set; }

    [JsonPropertyName("PendingRequestId")]
    public Guid? PendingRequestId { get; set; }

    [JsonPropertyName("MutualFriendsCount")]
    public int MutualFriendsCount { get; set; }

    [JsonPropertyName("ActivityApplicationName")]
    public string? ActivityApplicationName { get; set; }

    [JsonPropertyName("ActivityType")]
    public ActivityType? ActivityType { get; set; }

    [JsonPropertyName("ActivityStartedAt")]
    public DateTime? ActivityStartedAt { get; set; }
}
