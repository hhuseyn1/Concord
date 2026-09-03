using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class FriendRequestSummary
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("User")]
    public PublicProfileResponse User { get; set; } = null!;

    [JsonPropertyName("Created")]
    public DateTime Created { get; set; }
}
