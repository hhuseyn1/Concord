using System.Text.Json.Serialization;

namespace Concord.Application.Models;

/// <summary>Site-wide stat tiles for the admin dashboard (P4) - one query per number, all read-only.</summary>
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

    /// <summary>Rows in ServerBan whose expiry hasn't passed - mirrors ModerationService.GetBansAsync's definition of "active".</summary>
    [JsonPropertyName("ActiveBans")]
    public int ActiveBans { get; set; }

    /// <summary>Members whose TimedOutUntil is still in the future.</summary>
    [JsonPropertyName("ActiveTimeouts")]
    public int ActiveTimeouts { get; set; }

    [JsonPropertyName("TwoFactorEnabledUsers")]
    public int TwoFactorEnabledUsers { get; set; }

    /// <summary>Sessions whose Expires hasn't passed - a proxy for "currently signed in", since nothing tracks true liveness.</summary>
    [JsonPropertyName("ActiveSessions")]
    public int ActiveSessions { get; set; }

    [JsonPropertyName("NewUsersLast7Days")]
    public int NewUsersLast7Days { get; set; }

    [JsonPropertyName("NewServersLast7Days")]
    public int NewServersLast7Days { get; set; }
}
