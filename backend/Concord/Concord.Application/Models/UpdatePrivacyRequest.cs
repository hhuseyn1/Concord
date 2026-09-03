using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class UpdatePrivacyRequest
{
    [JsonPropertyName("FriendRequestPrivacy")]
    public FriendRequestPrivacy FriendRequestPrivacy { get; set; }

    [JsonPropertyName("DirectMessagePrivacy")]
    public DirectMessagePrivacy DirectMessagePrivacy { get; set; }

    [JsonPropertyName("ActivityVisibility")]
    public ActivityVisibility ActivityVisibility { get; set; }

    [JsonPropertyName("ReadReceiptsEnabled")]
    public bool ReadReceiptsEnabled { get; set; }
}
