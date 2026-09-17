using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class AdminSubscriptionSummary
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("UserId")]
    public Guid UserId { get; set; }

    [JsonPropertyName("Username")]
    public string Username { get; set; } = null!;

    [JsonPropertyName("Email")]
    public string Email { get; set; } = null!;

    [JsonPropertyName("Status")]
    public string Status { get; set; } = null!;

    [JsonPropertyName("CurrentPeriodEnd")]
    public DateTime? CurrentPeriodEnd { get; set; }

    [JsonPropertyName("CancelAtPeriodEnd")]
    public bool CancelAtPeriodEnd { get; set; }

    [JsonPropertyName("StripeCustomerId")]
    public string StripeCustomerId { get; set; } = null!;

    [JsonPropertyName("StripeSubscriptionId")]
    public string StripeSubscriptionId { get; set; } = null!;

    [JsonPropertyName("Created")]
    public DateTime Created { get; set; }
}
