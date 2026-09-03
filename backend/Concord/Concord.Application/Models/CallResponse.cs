using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class CallResponse
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("ConversationId")]
    public Guid ConversationId { get; set; }

    [JsonPropertyName("InitiatorId")]
    public Guid InitiatorId { get; set; }

    [JsonPropertyName("CalleeId")]
    public Guid CalleeId { get; set; }

    [JsonPropertyName("Type")]
    public CallType Type { get; set; }

    [JsonPropertyName("Status")]
    public CallStatus Status { get; set; }

    [JsonPropertyName("Created")]
    public DateTime Created { get; set; }

    [JsonPropertyName("AnsweredAt")]
    public DateTime? AnsweredAt { get; set; }

    [JsonPropertyName("EndedAt")]
    public DateTime? EndedAt { get; set; }

    [JsonPropertyName("DurationSeconds")]
    public int? DurationSeconds { get; set; }
}
