using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class SetUserRoleRequest
{
    [JsonPropertyName("Role")]
    public string? Role { get; set; }
}
