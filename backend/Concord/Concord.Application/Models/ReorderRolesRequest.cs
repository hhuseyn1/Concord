using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ReorderRolesRequest
{
    /// <summary>Role ids lowest-rank-first. The default role is excluded and stays at position 0.</summary>
    [JsonPropertyName("RoleIds")]
    public List<Guid> RoleIds { get; set; } = [];
}
