using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class ChannelResponse
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("ServerId")]
    public Guid ServerId { get; set; }

    [JsonPropertyName("Name")]
    public string? Name { get; set; }

    [JsonPropertyName("Type")]
    public ChannelType Type { get; set; }

    /// <summary>Manual sort order within this channel's <see cref="Type"/> group (P3) - lower sorts
    /// first. Does not order across Text vs Voice; each group has its own sequence.</summary>
    [JsonPropertyName("Position")]
    public int Position { get; set; }

    [JsonPropertyName("Created")]
    public DateTime Created { get; set; }

    /// <summary>Messages in this channel created after the caller's last-read marker (M-04); always 0
    /// for `Voice` channels and for responses that don't represent a per-viewer read (e.g. right after
    /// creating/updating a channel).</summary>
    [JsonPropertyName("UnreadCount")]
    public int UnreadCount { get; set; }
}
