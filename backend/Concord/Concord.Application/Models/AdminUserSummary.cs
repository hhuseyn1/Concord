using System.Text.Json.Serialization;

namespace Concord.Application.Models;

/// <summary>One row of the admin user table (P4) - deliberately not PublicProfileResponse, which is
/// scoped to what any other user is allowed to see. An admin sees the account fields that matter for
/// moderation instead: email, role, and account-status flags.</summary>
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

    /// <summary>"Admin" or "User" - the Domain-layer Roles enum can't appear here directly (Domain
    /// references Application, not the reverse), so it's stringified at the mapping boundary.</summary>
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
