using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class MyProfileResponse
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("Username")]
    public string? Username { get; set; }

    [JsonPropertyName("Name")]
    public string? Name { get; set; }

    [JsonPropertyName("Surname")]
    public string? Surname { get; set; }

    [JsonPropertyName("Email")]
    public string? Email { get; set; }

    /// <summary>"Admin" or "User" - lets the client gate admin-only UI without a round trip.</summary>
    [JsonPropertyName("Role")]
    public string? Role { get; set; }

    [JsonPropertyName("PhoneNumber")]
    public string? PhoneNumber { get; set; }

    [JsonPropertyName("AvatarUrl")]
    public string? AvatarUrl { get; set; }

    [JsonPropertyName("Locale")]
    public string? Locale { get; set; }

    [JsonPropertyName("NotificationsMuted")]
    public bool NotificationsMuted { get; set; }

    [JsonPropertyName("NotificationsSoundEnabled")]
    public bool NotificationsSoundEnabled { get; set; }

    [JsonPropertyName("Status")]
    public PresenceStatus Status { get; set; }

    [JsonPropertyName("CustomStatusEmoji")]
    public string? CustomStatusEmoji { get; set; }

    [JsonPropertyName("CustomStatusText")]
    public string? CustomStatusText { get; set; }

    [JsonPropertyName("CustomStatusExpiresAt")]
    public DateTime? CustomStatusExpiresAt { get; set; }

    [JsonPropertyName("FriendRequestPrivacy")]
    public FriendRequestPrivacy FriendRequestPrivacy { get; set; }

    [JsonPropertyName("DirectMessagePrivacy")]
    public DirectMessagePrivacy DirectMessagePrivacy { get; set; }

    [JsonPropertyName("ActivityVisibility")]
    public ActivityVisibility ActivityVisibility { get; set; }

    [JsonPropertyName("ReadReceiptsEnabled")]
    public bool ReadReceiptsEnabled { get; set; }

    [JsonPropertyName("Created")]
    public DateTime Created { get; set; }

    [JsonPropertyName("ActivityApplicationName")]
    public string? ActivityApplicationName { get; set; }

    [JsonPropertyName("ActivityType")]
    public ActivityType? ActivityType { get; set; }

    [JsonPropertyName("ActivityStartedAt")]
    public DateTime? ActivityStartedAt { get; set; }
}
