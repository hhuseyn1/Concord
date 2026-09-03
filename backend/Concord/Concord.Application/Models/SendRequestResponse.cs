using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class SendRequestResponse
{
    [JsonPropertyName("RequestId")]
    public Guid RequestId { get; set; }

    [JsonPropertyName("Status")]
    public FriendRequestStatus Status { get; set; }
}
