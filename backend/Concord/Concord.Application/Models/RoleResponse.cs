using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class RoleResponse
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("ServerId")]
    public Guid ServerId { get; set; }

    [JsonPropertyName("Name")]
    public string? Name { get; set; }

    [JsonPropertyName("Color")]
    public string? Color { get; set; }

    [JsonPropertyName("Permissions")]
    public long Permissions { get; set; }

    [JsonPropertyName("PermissionNames")]
    public List<string> PermissionNames { get; set; } = [];

    [JsonPropertyName("Position")]
    public int Position { get; set; }

    [JsonPropertyName("IsDefault")]
    public bool IsDefault { get; set; }

    [JsonPropertyName("MemberCount")]
    public int MemberCount { get; set; }
}
