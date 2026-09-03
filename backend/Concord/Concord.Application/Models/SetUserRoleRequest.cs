using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class SetUserRoleRequest
{
    /// <summary>"Admin" or "User" - parsed against Concord.Domain.Enums.Roles server-side.</summary>
    [JsonPropertyName("Role")]
    public string? Role { get; set; }
}
