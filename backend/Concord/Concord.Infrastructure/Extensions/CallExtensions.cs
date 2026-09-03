using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Domain.Entities;

namespace Concord.Infrastructure.Extensions;

public static class CallExtensions
{
    public static CallResponse MapToResponse(this Call call) => new()
    {
        Id = call.Id,
        ConversationId = call.ConversationId,
        InitiatorId = call.InitiatorId,
        CalleeId = call.CalleeId,
        Type = call.Type,
        Status = call.Status,
        Created = call.Created,
        AnsweredAt = call.AnsweredAt,
        EndedAt = call.EndedAt,
        DurationSeconds = call.Status == CallStatus.Ended && call.AnsweredAt.HasValue && call.EndedAt.HasValue
            ? (int)(call.EndedAt.Value - call.AnsweredAt.Value).TotalSeconds
            : null
    };
}
