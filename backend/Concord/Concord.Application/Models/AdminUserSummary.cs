using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class AdminUserSummary
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("Username")]
    public string? Username { get; set; }

    [JsonPropertyName("Name")]
    public string? Name { get; set; }

    [JsonPropertyName("Surname")]
    public string? Surname { get; set; }

    [JsonPropertyName("Email")]
    public string? Email { get; set; }

    [JsonPropertyName("PhoneNumber")]
    public string? PhoneNumber { get; set; }

    [JsonPropertyName("AvatarUrl")]
    public string? AvatarUrl { get; set; }

    [JsonPropertyName("Role")]
    public string? Role { get; set; }

    [JsonPropertyName("Disabled")]
    public bool Disabled { get; set; }

    [JsonPropertyName("TwoFactorEnabled")]
    public bool TwoFactorEnabled { get; set; }

    [JsonPropertyName("LockedOut")]
    public bool LockedOut { get; set; }

    [JsonPropertyName("Created")]
    public DateTime Created { get; set; }
}
