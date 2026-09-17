using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ReorderChannelsRequest
{
    [JsonPropertyName("ChannelIds")]
    public List<Guid> ChannelIds { get; set; } = [];
}
