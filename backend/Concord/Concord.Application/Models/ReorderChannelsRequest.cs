using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ReorderChannelsRequest
{
    /// <summary>Every channel id of one <c>ChannelType</c> group (Text or Voice), in the desired
    /// order. Mirrors <see cref="ReorderRolesRequest"/> - one flat, complete list per call rather than
    /// a partial reorder, so there is no ambiguity about where an omitted channel would land.</summary>
    [JsonPropertyName("ChannelIds")]
    public List<Guid> ChannelIds { get; set; } = [];
}
