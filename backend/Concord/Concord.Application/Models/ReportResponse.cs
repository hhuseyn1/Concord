using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

/// <summary>One row of the moderator report queue. Denormalizes enough of the target to be readable
/// without a second round-trip - see <see cref="TargetSnippet"/>.</summary>
public class ReportResponse
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("Reporter")]
    public PublicProfileResponse Reporter { get; set; } = null!;

    [JsonPropertyName("TargetType")]
    public ReportTargetType TargetType { get; set; }

    [JsonPropertyName("TargetId")]
    public Guid TargetId { get; set; }

    /// <summary>A best-effort preview of the target - a message's content, or the reported user's
    /// display name - so the queue is readable without a second round-trip. Null when the underlying
    /// target can no longer be resolved (e.g. the message was hard-deleted since the report was
    /// filed, or the user account no longer exists).</summary>
    [JsonPropertyName("TargetSnippet")]
    public string? TargetSnippet { get; set; }

    [JsonPropertyName("Reason")]
    public string Reason { get; set; } = null!;

    [JsonPropertyName("Status")]
    public ReportStatus Status { get; set; }

    [JsonPropertyName("ResolvedByUserId")]
    public Guid? ResolvedByUserId { get; set; }

    [JsonPropertyName("ResolvedAtUtc")]
    public DateTime? ResolvedAtUtc { get; set; }

    [JsonPropertyName("CreatedUtc")]
    public DateTime CreatedUtc { get; set; }
}
