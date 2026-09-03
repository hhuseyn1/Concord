using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class TransferOwnershipRequest
{
    [JsonPropertyName("NewOwnerUserId")]
    public Guid NewOwnerUserId { get; set; }
}
