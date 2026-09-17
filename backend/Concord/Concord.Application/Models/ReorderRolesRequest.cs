using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ReorderRolesRequest
{
    [JsonPropertyName("RoleIds")]
    public List<Guid> RoleIds { get; set; } = [];
}
