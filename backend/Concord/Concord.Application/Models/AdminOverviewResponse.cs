using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class AdminOverviewResponse
{
    [JsonPropertyName("TotalUsers")]
    public int TotalUsers { get; set; }

    [JsonPropertyName("DisabledUsers")]
    public int DisabledUsers { get; set; }

    [JsonPropertyName("TotalServers")]
    public int TotalServers { get; set; }

    [JsonPropertyName("TotalMessages")]
    public int TotalMessages { get; set; }

    [JsonPropertyName("TotalDirectMessages")]
    public int TotalDirectMessages { get; set; }

    [JsonPropertyName("ActiveBans")]
    public int ActiveBans { get; set; }

    [JsonPropertyName("ActiveTimeouts")]
    public int ActiveTimeouts { get; set; }

    [JsonPropertyName("TwoFactorEnabledUsers")]
    public int TwoFactorEnabledUsers { get; set; }

    [JsonPropertyName("ActiveSessions")]
    public int ActiveSessions { get; set; }

    [JsonPropertyName("NewUsersLast7Days")]
    public int NewUsersLast7Days { get; set; }

    [JsonPropertyName("NewServersLast7Days")]
    public int NewServersLast7Days { get; set; }
}
