using System.Text.Json.Serialization;

namespace Concord.Application.Models;

/// <summary>One emoji's aggregated reaction state on a message (M-01). Deliberately viewer-independent
/// (a plain list of reactor ids, not a pre-computed count/"did I react" bool) - unlike
/// <c>MessageResponse.Sender</c>'s presence gate, this response is broadcast unchanged to every
/// recipient of `MessageReactionsChanged` (see `MessagesController`), so anything relative to "the
/// current viewer" would be wrong for everyone except whoever triggered the toggle. Each client derives
/// its own count/"did I react" from `UserIds` against its own signed-in user id.</summary>
public class ReactionSummaryResponse
{
    [JsonPropertyName("Emoji")]
    public string Emoji { get; set; } = string.Empty;

    [JsonPropertyName("UserIds")]
    public List<Guid> UserIds { get; set; } = [];
}
