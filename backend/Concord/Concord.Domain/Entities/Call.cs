using Concord.Application.Enums;

namespace Concord.Domain.Entities;

public class Call : BaseEntity
{
    public Guid Id { get; set; }

    public Guid ConversationId { get; set; }

    public Guid InitiatorId { get; set; }
    public Guid CalleeId { get; set; }

    public CallType Type { get; set; }
    public CallStatus Status { get; set; }

    public DateTime? AnsweredAt { get; set; }
    public DateTime? EndedAt { get; set; }
}
