using System.Text.Json.Serialization;
using Concord.Application.Enums;

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

    /// <summary>Raw bitfield, so a client can test a single flag without a round trip.</summary>
    [JsonPropertyName("Permissions")]
    public long Permissions { get; set; }

    /// <summary>The same bitfield split into flag names, for display without duplicating the enum.</summary>
    [JsonPropertyName("PermissionNames")]
    public List<string> PermissionNames { get; set; } = [];

    [JsonPropertyName("Position")]
    public int Position { get; set; }

    [JsonPropertyName("IsDefault")]
    public bool IsDefault { get; set; }

    [JsonPropertyName("MemberCount")]
    public int MemberCount { get; set; }
}
